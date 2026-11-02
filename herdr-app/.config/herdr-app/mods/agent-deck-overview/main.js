// agent-deck: every agent on every machine, in a lane per state, grouped by machine;
// a Terminals tab shows every live terminal, a lane per machine, with what runs and its last lines.
// Local changes from upstream: see "Vendored mods" in herdr-app/README.md.
// Opened with `mod.open:agent-deck-overview` (again: closes it); a card goes to its agent.

import { View, div, svg, image } from "gpui-kit";
import { v_flex, h_flex, Scrollbar, v_virtual_list, VirtualListScrollHandle } from "gpui-base";
import { spaces, agents, terminals, panes, run, hc, theme, props, closeOverlay, settings, nextCommand } from "herdr";

const WORD = { blocked: "needs you", done: "done", working: "working", idle: "idle" };
// Most urgent first, always the same width, so nothing moves as agents change state.
const LANES = [
  ["blocked", "Needs you", "Nothing needs you"],
  ["working", "Working", "Nothing running"],
  ["done", "Done", "Nothing new"],
  ["idle", "Idle", "No idle agents"],
];
const CARD_H = 62; // an agent card; rows are fixed so a lane can scroll to its selection
const ROW_GAP = 6;
const HEAD_H = 24; // a machine's heading inside a lane
const TERM_COLS = 3; // terminal cards to a row, when one machine has the whole width
const clean = (s) => (s ?? "").replace(/^[^\p{L}\p{N}]+/u, "").trim();
// The agent's own title (Claude's chat name) when it says something, else its program.
function chatName(a) {
  const live = clean(a.title);
  const telling = live && live !== a.program?.name && !/^[~/]|^[A-Za-z]:\\/.test(live) && !live.includes("@") && live.toLowerCase() !== a.program?.key;
  return telling ? live : a.program?.name || a.address;
}
function duration(ms) {
  const m = Math.floor(ms / 60000);
  if (m < 1) return "<1m";
  if (m < 60) return `${m}m`;
  const h = Math.floor(m / 60);
  return h < 24 ? `${h}h` : `${Math.floor(h / 24)}d`;
}
function icon(p, size, color) {
  if (!p?.icon) return null;
  return p.tint ? svg(p.icon).size(size).flex_none().text_color(color) : image(p.icon).w(size).h(size).flex_none();
}
const short = (cwd) => (cwd ? cwd.replace(/^\/private(?=\/(tmp|var)\/)/, "").replace(/^\/(Users|home)\/[^/]+/, "~").replace(/^\/root(?=\/|$)/, "~") : "");
const PREVIEW = 2; // last non-empty screen lines on a terminal card
const machineOf = (address) => (address.includes("/") ? address.slice(0, address.lastIndexOf("/")) : null);

export default class Overview extends View {
  init(_props, cx) {
    this.machines = [];
    this.tab = localStorage.getItem("tab") ?? "agents";
    this.preview = {}; // address -> its last lines
    this.selected = null; // address of the card the keyboard is on
    this.grid = []; // what's drawn: lanes of { address, go, row }
    this.scrolls = Object.fromEntries(LANES.map(([k]) => [k, VirtualListScrollHandle.new()])); // lane -> its scroll handle
    this.handle = cx.focus_handle();
    this.handle.focus();
    this.refresh(cx);
    this.read(cx);
    cx.timer.every(30000, (cx) => this.refresh(cx));
    cx.timer.every(8000, (cx) => this.read(cx));
    // `agent-deck-overview.agents` / `agent-deck-overview.terminals` pick the tab (keys can name them).
    cx.spawn(async (cx) => {
      for (;;) {
        const c = await nextCommand();
        if (c === "agents" || c === "terminals") this.show(c, cx);
      }
    });
  }

  // The last lines of every live terminal, one at a time, while the Terminals tab shows.
  read(cx) {
    if (this.tab !== "terminals" || this.reading) return;
    this.reading = true;
    cx.spawn(async (cx) => {
      const reading = terminals().filter((x) => x.state === "live" && !x.program?.agent);
      // Lines of terminals that are gone go too.
      this.preview = Object.fromEntries(reading.filter((x) => this.preview[x.address]).map((x) => [x.address, this.preview[x.address]]));
      for (const x of reading) {
        try {
          const r = await hc(["read", x.address]);
          if (r.code === 0) this.preview[x.address] = r.stdout.split("\n").map((l) => l.trimEnd()).filter((l) => l.trim()).slice(-PREVIEW);
        } catch {}
      }
      this.reading = false;
      cx.notify();
    });
  }

  show(tab, cx) {
    this.tab = tab;
    localStorage.setItem("tab", tab);
    this.read(cx);
    cx.notify();
  }

  refresh(cx) {
    cx.spawn(async (cx) => {
      try {
        const r = await hc(["machine", "ls", "--json"]);
        if (r.code === 0) this.machines = (JSON.parse(r.stdout).machines ?? []).filter((m) => !m.temporary);
      } catch {}
      cx.notify();
    });
  }

  // Not `close`: Herdr calls a View's close(cx) itself when the overlay goes.
  dismiss() {
    const id = props()?.overlay;
    if (id) closeOverlay(id);
  }

  // Arrows or hjkl. On agents, up and down stay in a lane and sideways changes lane;
  // on terminals every direction walks the list.
  move(dx, dy, cx) {
    const lanes = this.tab === "terminals" ? [this.grid.flat()] : this.grid.filter((l) => l.length);
    if (!lanes.length) return;
    const step = this.tab === "terminals" ? dx + dy : dy;
    let l = lanes.findIndex((lane) => lane.some((c) => c.address === this.selected));
    if (l < 0) l = 0;
    let i = Math.max(0, lanes[l].findIndex((c) => c.address === this.selected));
    if (this.tab !== "terminals" && dx) {
      l = Math.min(lanes.length - 1, Math.max(0, l + dx));
      i = Math.min(i, lanes[l].length - 1);
    } else i = Math.min(lanes[l].length - 1, Math.max(0, i + step));
    const card = lanes[l][i];
    this.selected = card.address;
    if (card.lane) this.scrolls[card.lane].scroll_to_item(card.row);
    cx.notify();
  }

  key(e, cx) {
    const step = { up: [0, -1], k: [0, -1], down: [0, 1], j: [0, 1], left: [-1, 0], h: [-1, 0], right: [1, 0], l: [1, 0] }[e.key];
    if (step) return this.move(step[0], step[1], cx);
    if (e.key === "enter") return this.grid.flat().find((c) => c.address === this.selected)?.go();
    if (e.key === "t") return this.show(this.tab === "terminals" ? "agents" : "terminals", cx);
    if (e.key === "escape") this.dismiss();
  }

  // Which lane a card is in is the lane's job to say, so a card only shows what's left.
  // Drawn inside a virtual list, so the list takes the click (see on_item_click).
  card(t, a, tab, now) {
    const since = a.status === "working" ? tab?.working_since : tab?.changed_at;
    const name = chatName(a);
    // A tab's automatic number, or the chat name again, says nothing.
    const tabName = a.tab_name && !/^\d+$/.test(a.tab_name) && a.tab_name !== name ? a.tab_name : null;
    return v_flex()
      .id(`ov-${a.address}`)
      .w_full()
      .h(CARD_H)
      .flex_none()
      .justify_center()
      .px(10)
      .gap(4)
      .rounded(8)
      .bg(this.selected === a.address ? t.selected : t.surface)
      .border(1)
      .border_color(this.selected === a.address ? t.accent : a.status === "blocked" ? t.blocked : t.border)
      .cursor_pointer()
      .hover((s) => s.bg(t.hover))
      .child(h_flex().gap(8).items_center().min_w(0)
        .when(Boolean(a.program?.icon), (el) => el.child(icon(a.program, 15, t.foreground)))
        .child(div().flex_1().min_w(0).truncate().text_size(13).when(a.status !== "idle", (el) => el.font_semibold()).text_color(t.foreground).child(name)))
      .child(h_flex().gap(8).items_center().min_w(0).text_size(11.5).text_color(t.dim)
        .child(div().flex_1().min_w(0).truncate().child(tabName ? `${a.space_name} · ${tabName}` : a.space_name))
        .when(a.focused, (el) => el.child(div().flex_none().text_color(t.muted).child("here")))
        .when(Boolean(since), (el) => el.child(div().flex_none().child(duration(now - since)))));
  }

  term(t, x, shown, title, status, now, go) {
    const g = x.program;
    const fg = x.foreground;
    // A command reads as typed: `make test`, not /usr/bin/make test.
    const running = g?.agent || g?.shell ? null : (fg?.argv?.length ? [fg.argv[0].split("/").pop(), ...fg.argv.slice(1)].join(" ") : g?.name);
    // An agent's state as the Agents tab has it ("done" turns "idle" once seen).
    const state = g?.agent ? status ?? x.status ?? "idle" : running ? "running" : "idle";
    const color = g?.agent ? t[state] ?? t.dim : running ? t.accent : t.dim;
    const name = g?.agent ? chatName({ title: title ?? x.title, program: g, address: x.address }) : running ?? `${g?.name ?? "shell"}`;
    const where = shown ? x.labels?.where ?? "" : "hidden";
    // An agent's screen is its own chrome; what it last reported says more.
    const lines = g?.agent ? (x.report?.msg ? [x.report.msg] : []) : this.preview[x.address] ?? [];
    const selected = this.selected === x.address;
    return v_flex()
      .id(`ov-t-${x.address}`)
      .flex_1()
      .min_w(0)
      .px(10)
      .py(8)
      .gap(4)
      .rounded(8)
      .bg(selected ? t.selected : t.surface)
      .border(1)
      .border_color(selected ? t.accent : state === "blocked" ? t.blocked : t.border)
      .cursor_pointer()
      .hover((s) => s.bg(t.hover))
      .tooltip(shown ? "Go to it" : "Peek (it is in no space)")
      .on_click(go)
      .child(h_flex().gap(8).items_center().min_w(0)
        .child(g?.icon ? icon(g, 15, t.foreground) : div().flex_none().text_size(11).text_color(t.dim).child(">_"))
        .child(div().flex_1().min_w(0).truncate().text_size(13).when(state !== "idle", (el) => el.font_semibold()).text_color(t.foreground).child(name))
        .child(div().flex_none().text_size(11.5).text_color(color).child(WORD[state] ?? state)))
      .child(h_flex().gap(8).items_center().min_w(0).text_size(11.5).text_color(t.dim)
        .child(div().flex_1().min_w(0).truncate().child(short(fg?.cwd ?? x.cwd)))
        .child(div().flex_none().text_color(shown ? t.dim : t.done).child(where))
        .when(Boolean(x.created_ms), (el) => el.child(div().flex_none().child(duration(now - x.created_ms)))))
      .when(lines.length > 0, (el) => el.child(v_flex().mt(2).px(6).py(4).rounded(4).bg(t.chrome).font_family(settings()?.font_family ?? "monospace").text_size(10.5).text_color(t.dim)
        .children(lines.map((l, i) => div().id(`ov-tl-${x.address}-${i}`).truncate().child(l)))));
  }

  render(cx) {
    const t = theme();
    const now = Date.now();
    const all = agents();
    const sp = spaces();
    const tabs = new Map(sp.flatMap((s) => s.tabs).map((x) => [x.id, x]));
    const inPanes = new Set(panes().map((p) => p.terminal).filter(Boolean));
    const live = terminals().filter((x) => x.state === "live");
    const names = [null, ...[...new Set([...sp.map((s) => s.machine).filter(Boolean), ...this.machines.map((m) => m.name)])].sort()];

    const spaceOf = new Map(sp.map((s) => [s.id, s]));
    const machineOfAgent = (a) => spaceOf.get(a.space)?.machine ?? null;

    const many = names.length > 1; // only then does saying which machine tell you anything

    const strip = h_flex().id("ov-machines").flex_none().flex_wrap().gap(8).px(16).py(8).border_b(1).border_color(t.border)
      .children(names.map((m) => {
        const machine = this.machines.find((k) => k.name === m);
        const connected = !m || machine?.state === "connected";
        const terms = live.filter((x) => machineOf(x.address) === m);
        const hidden = terms.filter((x) => !inPanes.has(x.address)).length;
        const n = all.filter((a) => machineOfAgent(a) === m).length;
        return h_flex().id(`ov-m-${m ?? "local"}`).gap(6).items_center().px(8).py(3).rounded(6).bg(t.surface).text_size(11.5).text_color(t.dim)
          .tooltip(`${connected ? "connected" : (machine?.state ?? "asleep").replace(/_/g, " ")}${machine?.version ? ` · hc ${machine.version}` : ""} · ${terms.length} terminals${hidden ? `, ${hidden} hidden` : ""}`)
          .child(div().size(7).rounded(4).flex_none().bg(connected ? t.ansi2 : t.dim))
          .child(div().text_color(t.foreground).child(m ?? "This computer"))
          .child(div().child(`${n} agent${n === 1 ? "" : "s"} · ${terms.length} terms`));
      }));

    const machineHead = (m, n) => h_flex().flex_none().gap(6).items_center().px(2).pt(4).text_size(11.5).text_color(t.dim)
      .child(svg(`mods/workspace-chrome/${m ? "server" : "monitor"}.svg`).size(12).flex_none())
      .child(div().flex_1().truncate().child(m ?? "This computer"))
      .child(div().child(String(n)));

    const laneHead = (color, title, count) => h_flex().h(36).flex_none().px(12).gap(8).items_center().border_b(1).border_color(t.border)
      .child(div().size(8).rounded(4).flex_none().bg(color))
      .child(div().flex_1().min_w(0).truncate().text_size(13).font_semibold().text_color(count ? t.foreground : t.muted).child(title))
      .child(div().flex_none().text_size(11.5).text_color(t.dim).child(String(count)));

    const goAgent = (a) => () => {
      run("agent.focus", { terminal: a.address });
      this.dismiss();
    };
    const goTerm = (x, shown) => () => {
      run(shown ? "pane.focus" : "terminal.peek", { terminal: x.address });
      this.dismiss();
    };
    const statusOf = new Map(all.map((a) => [a.address, a.status]));
    const titles = new Map(panes().filter((p) => p.terminal).map((p) => [p.terminal, p.title]));
    const onTerms = this.tab === "terminals";

    // A lane's body lists its cards and machine headers side by side, so a card's row
    // is its place in the scroll list.
    this.grid = [];
    const lane = ([k, title, empty]) => {
      const list = all.filter((a) => a.status === k).sort((x, y) => y.seq - x.seq);
      const rows = [];
      const cards = [];
      for (const m of names) {
        const mine = list.filter((a) => machineOfAgent(a) === m);
        if (mine.length && many) rows.push({ head: m, n: mine.length });
        for (const a of mine) {
          const go = goAgent(a);
          cards.push({ address: a.address, go, lane: k, row: rows.length });
          rows.push({ a, go });
        }
      }
      this.grid.push(cards);
      return { k, title, empty, n: list.length, rows };
    };
    const lanes = onTerms ? [] : LANES.map(lane);

    // Terminals: a lane per machine; shown ones first, busy before idle, hidden last.
    const terms = onTerms ? names.map((m) => {
      const rank = (x) => (inPanes.has(x.address) ? 0 : 4) + (x.program?.agent ? 1 : x.program?.shell ? 2 : 0);
      const list = live.filter((x) => machineOf(x.address) === m).sort((a, b) => rank(a) - rank(b) || (b.created_ms ?? 0) - (a.created_ms ?? 0));
      this.grid.push(list.map((x) => ({ address: x.address, go: goTerm(x, inPanes.has(x.address)) })));
      return { m, list };
    }) : [];

    // Whatever is on screen has a card selected, most urgent first.
    const flat = this.grid.flat();
    if (!flat.some((c) => c.address === this.selected)) this.selected = flat[0]?.address ?? null;

    const drawLane = ({ k, title, empty, n, rows }) => v_flex().id(`ov-lane-${k}`).flex_1().min_w(0).min_h(0).rounded(10).bg(t.chrome).border(1).border_color(t.border)
      .child(laneHead(t[k] ?? t.dim, title, n))
      .child(n === 0
        ? div().p(12).text_size(12).text_color(t.dim).child(empty)
        : div().relative().flex_1().min_h(0).px(8).pt(8)
          .child(v_virtual_list(`ov-lane-body-${k}`, rows.length, rows.map((r) => (r.a ? CARD_H + ROW_GAP : HEAD_H)),
            (i) => rows[i].a?.address ?? `head-${rows[i].head ?? "local"}`,
            ({ start, end }) => rows.slice(start, end).map((r) => (r.a
              ? div().w_full().pb(ROW_GAP).child(this.card(t, r.a, tabs.get(r.a.tab), now))
              : machineHead(r.head, r.n))))
            .size_full().track_scroll(this.scrolls[k])
            .on_item_click((key) => rows.find((r) => r.a?.address === key)?.go()))
          .child(Scrollbar.vertical(`ov-lane-body-${k}`).viewport_from_layout().absolute().inset_0()));

    const drawTerms = ({ m, list }) => {
      const machine = this.machines.find((k) => k.name === m);
      const connected = !m || machine?.state === "connected";
      const cols = many ? 1 : TERM_COLS;
      const busyN = list.filter((x) => !x.program?.agent && !x.program?.shell).length;
      const hidden = list.filter((x) => !inPanes.has(x.address)).length;
      // Rows of equal cells, with blanks filling the last, so every card is the same width.
      const rows = [];
      for (let i = 0; i < list.length; i += cols) rows.push(list.slice(i, i + cols));
      return v_flex().id(`ov-tlane-${m ?? "local"}`).flex_1().min_w(0).min_h(0).rounded(10).bg(t.chrome).border(1).border_color(t.border)
        .when(many, (el) => el.child(laneHead(connected ? t.ansi2 : t.dim, m ?? "This computer", list.length)))
        .child(v_flex().id(`ov-tlane-body-${m ?? "local"}`).flex_1().min_h(0).p(8).gap(6).overflow_y_scrollbar()
          .when(list.length === 0, (el) => el.child(div().p(4).text_size(12).text_color(t.dim).child(connected ? "No terminals" : (machine?.state ?? "asleep").replace(/_/g, " "))))
          .when(busyN + hidden > 0, (el) => el.child(div().flex_none().px(2).text_size(11.5).text_color(t.dim).child([busyN && `${busyN} running`, hidden && `${hidden} hidden`].filter(Boolean).join(" · "))))
          .children(rows.map((row, i) => h_flex().id(`ov-trow-${m ?? "local"}-${i}`).flex_none().gap(6).items_stretch()
            .children(row.map((x) => this.term(t, x, inPanes.has(x.address), titles.get(x.address), statusOf.get(x.address), now, goTerm(x, inPanes.has(x.address)))))
            .children(Array.from({ length: cols - row.length }, () => div().flex_1().px(10).border(1).border_color("#00000000"))))));
    };

    const tabBtn = (id, text) => div().id(`ov-tab-${id}`).px(10).py(3).rounded(6).text_size(12).cursor_pointer()
      .when(this.tab === id, (el) => el.bg(t.selected).text_color(t.foreground))
      .when(this.tab !== id, (el) => el.text_color(t.dim).hover((s) => s.bg(t.hover).text_color(t.foreground)))
      .on_click((_e, cx) => this.show(id, cx))
      .child(text);

    return v_flex()
      .id("ov-root")
      .track_focus(this.handle)
      .on_key_down((e, cx) => this.key(e, cx))
      .size_full()
      .min_h(0)
      .text_size(13)
      .bg(t.background ?? t.chrome)
      .child(h_flex().h(44).flex_none().px(16).gap(10).items_center().border_b(1).border_color(t.border)
        .child(div().text_size(15).font_semibold().text_color(t.foreground).child("Overview"))
        .child(h_flex().gap(2).p(2).rounded(8).bg(t.chrome).child(tabBtn("agents", `Agents ${all.length}`)).child(tabBtn("terminals", `Terminals ${live.length}`)))
        .child(div().flex_1())
        .child(div().flex_none().text_size(11.5).text_color(t.dim).child("Arrows move · Enter go · T switch · Esc close"))
        .child(div().id("ov-close").p(4).rounded(4).text_color(t.dim).cursor_pointer()
          .hover((s) => s.bg(t.hover).text_color(t.foreground))
          .on_click(() => this.dismiss())
          .tooltip("Close (Esc)")
          .child(svg("mods/workspace-chrome/x.svg").size(14))))
      .when(many, (el) => el.child(strip))
      .child(h_flex().id("ov-body").flex_1().min_h(0).p(12).gap(10).items_stretch().children(onTerms ? terms.map(drawTerms) : lanes.map(drawLane)));
  }
}
