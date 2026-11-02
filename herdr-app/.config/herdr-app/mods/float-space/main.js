// Ctrl+Shift+Space: a floating scratch window with its own terminal tabs and shared notes.
// Hiding it keeps its shells running. Behaviour follows the "Float Space" recipe, without
// its agent alerts and custom border. A command can't focus a terminal in an overlay, so
// the header takes the keyboard on open and you click the terminal to type in it. While
// the header has it: c new, n/p switch, x end, z size, m notes, Esc hide.

import { View, div } from "gpui-kit";
import { h_flex, Textarea, TextareaState, v_flex } from "gpui-base";
import { closeOverlay, focused, hc, home, notify, openOverlay, panes, props, run, setShared, settings, shared, spaces, theme } from "herdr";

const KEY = "float-space.v1";
const MAX_TABS = 12;
const SIZES = [["S", 40, 50], ["M", 50, 60], ["L", 85, 88]];
const DEFAULTS = { tabs: [], active: null, page: "terminal", notes: "", size: 1, sequence: 0, started: false };

// Every copy of a mod shares globalThis: this is what the window is doing right now.
const live = (globalThis.__floatSpace ??= { window: null, generation: 0, returnPane: null });

const state = () => ({ ...DEFAULTS, ...(shared(KEY) ?? {}) });
const save = (next) => setShared(KEY, next);
const fail = (error) => notify({ title: "Float Space", body: String(error), level: "error" });

function startFolder() {
  const pane = panes().find((p) => p.pane === focused()?.pane);
  return pane?.cwd ?? focused()?.cwd ?? spaces().find((s) => s.active)?.folder ?? home();
}

async function startTerminal(s) {
  const r = await hc(["run", "--bg", "--keep", "--no-parent", "--json", "--cwd", startFolder(), "--label", "herdr.mod=float-space"]);
  if (r.code !== 0) throw new Error(r.stderr || `hc run exited ${r.code}`);
  const sequence = s.sequence + 1;
  const { address } = JSON.parse(r.stdout);
  return { ...s, sequence, tabs: [...s.tabs, { address, title: `Terminal ${sequence}` }], active: address, page: "terminal" };
}

// Drop tabs whose terminal ended while the window wasn't looking.
async function reconcile(s) {
  const r = await hc(["ls", "--json"]);
  if (r.code !== 0) throw new Error(r.stderr || `hc ls exited ${r.code}`);
  const alive = new Set(JSON.parse(r.stdout).terminals.map((t) => t.address));
  const tabs = s.tabs.filter((t) => alive.has(t.address));
  const active = tabs.some((t) => t.address === s.active) ? s.active : tabs[0]?.address ?? null;
  return { ...s, tabs, active, page: active ? s.page : "notes" };
}

function openWindow(s) {
  save(s);
  const [, width, height] = SIZES[s.size];
  const generation = ++live.generation;
  const body = s.page === "terminal" && s.active
    ? { terminal: s.active }
    : { mod: "float-space", props: { role: "notes" } };
  const previous = live.window;
  const key = `float-space.${width}x${height}`;
  // One key per size, so each size remembers where it was dropped. Opening the same
  // key replaces that window, and only a size change leaves an old one to close.
  live.window = openOverlay({
    kind: "window", key, width: width / 100, height: height / 100,
    layout: { type: "column", children: [
      { type: "block", size: { px: 30 }, content: { mod: "float-space", props: { role: "bar", generation } } },
      { type: "block", content: body },
    ] },
  });
  if (previous && live.key && live.key !== key) closeOverlay(previous);
  live.key = key;
}

function hide() {
  const open = live.window;
  live.window = null;
  live.generation++;
  if (open) closeOverlay(open);
  if (live.returnPane && panes().some((p) => p.pane === live.returnPane)) run("pane.focus", { pane: live.returnPane });
}

async function show() {
  live.returnPane = focused()?.pane ?? null;
  let s = await reconcile(state());
  if (!s.tabs.length && !s.started) s = { ...(await startTerminal(s)), started: true };
  openWindow(s);
}

class Bar {
  static render(view, cx, t) {
    const s = state();
    const stop = (e, cx) => cx.stop_propagation();
    const tab = (id, selected, label, onClick, extra) => h_flex().id(id).h(22).px(8).gap(6).flex_none().items_center().rounded(6).text_size(12)
      .bg(selected ? t.raised : t.background).text_color(selected ? t.foreground : t.muted)
      .hover((e) => e.bg(t.hover)).on_mouse_down("left", stop).on_click(onClick)
      .child(div().max_w(135).truncate().child(label)).when(Boolean(extra), (e) => e.child(extra));
    const button = (id, label, onClick) => h_flex().id(id).size(22).flex_none().items_center().justify_center().rounded(6).text_size(14)
      .text_color(t.dim).hover((e) => e.bg(t.hover).text_color(t.foreground)).on_mouse_down("left", stop).on_click(onClick).child(label);

    return h_flex().id("float-bar").size_full().px(6).gap(6).items_center().bg(t.background).border_b(1).border_color(t.border)
      .track_focus(view.handle).on_key_down((e, cx) => view.key(e, cx))
      .child(tab("notes", s.page === "notes", "Notes", () => openWindow({ ...s, page: "notes" })))
      .when(s.tabs.length > 0, (e) => e.child(div().w(1).h(14).bg(t.border)))
      .child(h_flex().id("float-tabs").flex_1().min_w(0).gap(2).items_center().overflow_x_scroll().children(s.tabs.map((item) =>
        tab(`tab-${item.address}`, s.page === "terminal" && s.active === item.address, item.title,
          () => openWindow({ ...s, active: item.address, page: "terminal" }),
          div().id(`end-${item.address}`).text_color(t.dim).hover((e) => e.text_color(t.foreground))
            .on_mouse_down("left", stop).on_click((_e, cx) => view.end(item.address, cx)).child("×")))))
      .child(button("float-new", "+", (_e, cx) => view.add(cx)))
      .child(button("float-size", SIZES[s.size][0], () => openWindow({ ...s, size: (s.size + 1) % SIZES.length })))
      .child(button("float-hide", "−", () => hide()));
  }
}

export default class FloatSpace extends View {
  init(_props, cx) {
    this.role = props()?.role ?? "toggle";
    if (this.role === "bar") {
      this.handle = cx.focus_handle();
      this.handle.focus();
    } else if (this.role === "notes") {
      this.notes = TextareaState.new({ value: state().notes, placeholder: "Notes shared across your spaces…", rows: 8 });
      this.notes.on("change", (_e, cx) => this.queueSave(cx));
      if (live.typeInNotes) {
        const end = state().notes.length;
        this.notes.set_selected_range({ start: end, end });
        this.notes.focus();
      }
      live.typeInNotes = false;
    } else {
      const overlay = props()?.overlay;
      cx.spawn(async () => {
        try {
          if (live.window) hide();
          else await show();
        } catch (error) {
          fail(error);
        }
        if (overlay) closeOverlay(overlay);
      });
    }
  }

  add(cx) {
    const s = state();
    if (s.tabs.length >= MAX_TABS) return fail(`At most ${MAX_TABS} terminals.`);
    cx.spawn(async () => {
      try {
        openWindow(await startTerminal(s));
      } catch (error) {
        fail(error);
      }
    });
  }

  end(address, cx) {
    const s = state();
    const at = s.tabs.findIndex((t) => t.address === address);
    const tabs = s.tabs.filter((t) => t.address !== address);
    const active = s.active === address ? tabs[Math.min(at, tabs.length - 1)]?.address ?? null : s.active;
    // Move off the terminal first: Herdr closes a window whose terminal ends.
    openWindow({ ...s, tabs, active, page: active ? s.page : "notes" });
    const ended = hc(["kill", address]);
    cx.spawn(async () => { await ended; });
  }

  // The header has the keyboard when the window opens, so its controls have keys too.
  key(e, cx) {
    const s = state();
    const at = s.tabs.findIndex((t) => t.address === s.active);
    const go = (by) => {
      const tab = s.tabs[(at + by + s.tabs.length) % s.tabs.length];
      if (tab) openWindow({ ...s, active: tab.address, page: "terminal" });
    };
    const keys = {
      escape: () => hide(),
      c: () => this.add(cx),
      n: () => go(1),
      p: () => go(-1),
      x: () => s.page === "terminal" && s.active && this.end(s.active, cx),
      z: () => openWindow({ ...s, size: (s.size + 1) % SIZES.length }),
      m: () => {
        live.typeInNotes = true;
        openWindow({ ...s, page: "notes" });
      },
    };
    if (!keys[e.key] || e.modifiers.control || e.modifiers.alt) return;
    cx.stop_propagation();
    keys[e.key]();
  }

  queueSave(cx) {
    const generation = (this.saveGeneration = (this.saveGeneration ?? 0) + 1);
    cx.timer.after(400, () => {
      if (generation === this.saveGeneration) this.saveNotes();
    });
  }

  saveNotes() {
    if (this.notes) save({ ...state(), notes: this.notes.value() });
  }

  // A window closes by itself when its terminal ends. Show the next tab if that's why.
  async close() {
    if (this.role === "notes") return this.saveNotes();
    if (this.role !== "bar" || props()?.generation !== live.generation || !live.window) return;
    live.window = null;
    const before = state();
    const s = await reconcile(before);
    if (s.tabs.length !== before.tabs.length) openWindow(s);
  }

  render(cx) {
    const t = theme();
    if (this.role === "bar") return Bar.render(this, cx, t);
    if (this.role === "notes") {
      return v_flex().size_full().px(16).py(14).bg(t.background).text_color(t.foreground)
        .font_family(settings().font ?? "JetBrains Mono").text_size(settings().font_size ?? 14)
        .child(Textarea.new(this.notes).size_full());
    }
    return div();
  }
}
