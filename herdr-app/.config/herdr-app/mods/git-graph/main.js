// A live `glola`: every branch's history as a graph, in the same columns and colors.
// Read-only on purpose, it never checks out or rewrites anything. Ctrl+Shift+G opens it
// on the focused terminal's repository; tab.new {mod: "git-graph", props: {folder}} docks it.

import { div, PathBuilder, View } from "gpui-kit";
import { h_flex, Scrollbar, v_flex, v_virtual_list } from "gpui-base";
import { closeOverlay, exec, focused, home, panes, props, settings, spaces, theme, watchFolder } from "herdr";

// ---- Reading the history. A single file because stow links each file, and a mod can't
// import a sibling whose link resolves outside its folder. tests/git-graph.test.ts covers this part.

export const PAGE = 300;
const FIELD = "%x00", RECORD = "%x01";
const FORMAT = ["%H", "%h", "%P", "%D", "%an", "%ae", "%at", "%s"].join(FIELD) + RECORD;

// The read-only form: writes nothing under .git, so it can't disturb running work.
export function gitArgs(...args) {
  return ["--no-optional-locks", "-c", "core.fsmonitor=false", "-c", "color.ui=false", ...args];
}

// All branches is `glola`, Current is `glol`.
export function logArgs({ all, remotes, limit }) {
  const refs = all
    ? ["--exclude=refs/stash", ...(remotes ? [] : ["--exclude=refs/remotes/*"]), "--all"]
    : ["HEAD"];
  return gitArgs("log", ...refs, "--date-order", `-n${limit + 1}`, `--format=${FORMAT}`, "--decorate=short");
}

export function parseRefs(text) {
  const refs = [];
  for (const raw of text.split(", ").filter(Boolean)) {
    if (raw.startsWith("HEAD -> ")) refs.push({ kind: "current", name: raw.slice(8) });
    else if (raw === "HEAD") refs.push({ kind: "head", name: "HEAD" });
    else if (raw.startsWith("tag: ")) refs.push({ kind: "tag", name: raw.slice(5) });
    else refs.push({ kind: raw.includes("/") ? "remote" : "branch", name: raw });
  }
  return refs;
}

export function parseLog(stdout) {
  return stdout.split("\x01").map((r) => r.replace(/^\n/, "")).filter(Boolean).map((record) => {
    const [hash, short, parents, refs, author, email, time, subject] = record.split("\0");
    return { hash, short, parents: parents ? parents.split(" ") : [], refs: parseRefs(refs ?? ""), author, email, time: Number(time), subject: subject ?? "" };
  });
}

// Each lane waits for one commit. A commit takes the lane waiting for it, closes any
// others waiting for it, and hands its lane to its first parent. A segment is
// [fromLane, fromY, toLane, toY, colorLane], with y in half rows.
export function layoutLanes(commits) {
  const lanes = [];
  const free = () => {
    const i = lanes.indexOf(null);
    return i === -1 ? lanes.length : i;
  };
  return commits.map((commit) => {
    const segments = [];
    let lane = lanes.indexOf(commit.hash);
    const arrived = lane !== -1;
    if (!arrived) lane = free();

    lanes.forEach((waiting, i) => {
      if (waiting === null) return;
      if (waiting !== commit.hash) segments.push([i, 0, i, 1, i]);
      else {
        segments.push([i, 0, lane, 0.5, i]);
        if (i !== lane) lanes[i] = null;
      }
    });

    lanes[lane] = null;
    commit.parents.forEach((parent, index) => {
      // The first parent always continues this lane, so a main line stays straight.
      if (index === 0) {
        lanes[lane] = parent;
        segments.push([lane, 0.5, lane, 1, lane]);
        return;
      }
      let target = lanes.indexOf(parent);
      if (target === -1) {
        target = free();
        lanes[target] = parent;
      }
      segments.push([lane, 0.5, target, 1, target]);
    });
    while (lanes.length && lanes[lanes.length - 1] === null) lanes.pop();
    return { commit, lane, segments, width: Math.max(lanes.length, lane + 1) };
  });
}

// The same words as git's %ar, shortened to fit a column.
export function age(time, now = Date.now() / 1000) {
  const s = Math.max(0, now - time);
  if (s < 60) return "now";
  if (s < 3600) return `${Math.floor(s / 60)}m`;
  if (s < 86400) return `${Math.floor(s / 3600)}h`;
  if (s < 86400 * 30) return `${Math.floor(s / 86400)}d`;
  if (s < 86400 * 365) return `${Math.floor(s / (86400 * 30))}mo`;
  return `${Math.floor(s / (86400 * 365))}y`;
}

export function parseNumstat(stdout) {
  return stdout.split("\n").filter(Boolean).map((line) => {
    const [added, removed, ...path] = line.split("\t");
    return { added, removed, path: path.join("\t") };
  });
}

// ---- The view

const ROW = 22, LANE = 12, PAD = 8, MAX_LANES = 24;
const LANE_COLORS = ["ansi4", "ansi2", "ansi5", "ansi3", "ansi6", "ansi1", "ansi12", "ansi10", "ansi13", "ansi11", "ansi14", "ansi9"];
const REF_COLORS = { current: "ansi2", head: "ansi6", branch: "ansi2", remote: "ansi1", tag: "ansi3" };

function folderNow() {
  if (props()?.folder) return props().folder;
  const pane = panes().find((p) => p.pane === focused()?.pane);
  return pane?.cwd ?? focused()?.cwd ?? spaces().find((s) => s.active)?.folder ?? home();
}

const shorten = (path) => (path.startsWith(home()) ? `~${path.slice(home().length)}` : path);

export default class GitGraph extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.handle.focus();
    this.all = true;
    this.remotes = true;
    this.limit = PAGE;
    this.rows = [];
    this.selected = null;
    this.details = null;
    this.diff = null;
    this.status = { kind: "loading" };
    this.request = 0;
    this.folder = folderNow();
    this.load(cx);
  }

  git(...args) {
    return exec("git", args, { cwd: this.folder });
  }

  load(cx) {
    const request = ++this.request;
    cx.spawn(async (cx) => {
      try {
        const top = await this.git("rev-parse", "--show-toplevel");
        if (request !== this.request) return;
        if (top.code !== 0) return this.show(cx, { kind: "empty", title: "Not a git repository", body: `${shorten(this.folder)} isn't inside a git repository. Focus a terminal in a repository to see its history.` });

        const root = top.stdout.trim();
        const log = await this.git(...logArgs(this));
        if (request !== this.request) return;
        if (log.code !== 0) {
          const unborn = /does not have any commits|bad revision 'HEAD'|ambiguous argument 'HEAD'/.test(log.stderr);
          return this.show(cx, unborn ? { kind: "empty", title: "No commits yet", body: `${shorten(root)} has no history.` } : { kind: "empty", title: "Can't read the history", body: log.stderr.trim(), error: true });
        }

        const commits = parseLog(log.stdout);
        this.more = commits.length > this.limit;
        this.rows = layoutLanes(commits.slice(0, this.limit));
        if (!this.rows.length && !this.all) return this.show(cx, { kind: "empty", title: "No commits yet", body: `${shorten(root)} has no history.` });
        this.startWatching(root, cx);
        this.show(cx, { kind: "ready", root });
      } catch (error) {
        if (request === this.request) this.show(cx, { kind: "empty", title: "Can't read the history", body: String(error), error: true });
      }
    });
  }

  show(cx, status) {
    this.status = status;
    cx.notify();
  }

  // Reload when refs or HEAD move, as `glola` would show on its next run.
  startWatching(root, cx) {
    if (this.watching === root) return;
    this.watching = root;
    cx.spawn(async (cx) => {
      const dir = await this.git("rev-parse", "--path-format=absolute", "--git-common-dir");
      if (dir.code !== 0) return;
      const gitDir = dir.stdout.trim();
      while (this.watching === root) {
        const changed = await watchFolder(gitDir);
        if (changed.some((path) => /(^|\/)(HEAD|packed-refs)$|\/refs\//.test(path))) this.load(cx);
      }
    });
  }

  toggle(name, cx) {
    this[name] = !this[name];
    this.limit = PAGE;
    this.load(cx);
  }

  loadMore(cx) {
    this.limit += PAGE;
    this.load(cx);
  }

  select(hash, cx) {
    if (this.selected === hash) return this.closeDetails(cx);
    this.selected = hash;
    this.details = null;
    this.diff = null;
    cx.notify();
    cx.spawn(async (cx) => {
      const [body, files] = await Promise.all([
        this.git(...gitArgs("show", "-s", "--format=%b", hash)),
        this.git(...gitArgs("show", "--format=", "--numstat", "-M", hash)),
      ]);
      if (this.selected !== hash) return;
      this.details = { body: body.stdout.trim(), files: parseNumstat(files.stdout) };
      cx.notify();
    });
  }

  closeDetails(cx) {
    this.selected = null;
    this.details = null;
    this.diff = null;
    cx.notify();
  }

  openDiff(path, cx) {
    const hash = this.selected;
    cx.spawn(async (cx) => {
      const r = await this.git(...gitArgs("show", "--format=", "--no-ext-diff", hash, "--", path));
      if (this.selected !== hash) return;
      this.diff = { path, lines: r.stdout.split("\n") };
      cx.notify();
    });
  }

  move(by, cx) {
    if (!this.rows.length) return;
    const at = this.rows.findIndex((r) => r.commit.hash === this.selected);
    const next = this.rows[Math.max(0, Math.min(this.rows.length - 1, at + by))];
    this.select(next.commit.hash, cx);
  }

  key(e, cx) {
    if (e.key === "escape") {
      cx.stop_propagation();
      if (this.diff) { this.diff = null; cx.notify(); return; }
      if (this.selected) return this.closeDetails(cx);
      if (props()?.overlay) closeOverlay(props().overlay);
      return;
    }
    if (e.key === "j" || e.key === "down") return this.move(1, cx);
    if (e.key === "k" || e.key === "up") return this.move(-1, cx);
  }

  // Elements follow the zoom, but paint_path takes raw pixels.
  graph(row, width, t) {
    const zoom = settings().zoom ?? 1;
    const x = (lane) => (PAD + lane * LANE + LANE / 2) * zoom;
    const y = (at) => at * ROW * zoom;
    const paths = new Map();
    for (const [from, fromY, to, toY, colorLane] of row.segments) {
      if (from >= MAX_LANES || to >= MAX_LANES) continue;
      const color = t[LANE_COLORS[colorLane % LANE_COLORS.length]];
      let path = paths.get(color) ?? PathBuilder.stroke(1.5 * zoom);
      path = path.move_to(x(from), y(fromY));
      if (from === to) path = path.line_to(x(to), y(toY));
      else {
        const mid = (y(fromY) + y(toY)) / 2;
        path = path.cubic_bezier_to(x(to), y(toY), x(from), mid, x(to), mid);
      }
      paths.set(color, path);
    }
    const dot = t[LANE_COLORS[row.lane % LANE_COLORS.length]];
    return div().relative().flex_none().w(width).h(ROW).overflow_hidden()
      .children([...paths].map(([color, path]) => window.paint_path(path.build(), color).absolute().top(0).left(0).size_full()))
      .child(div().absolute().left(PAD + Math.min(row.lane, MAX_LANES) * LANE + LANE / 2 - 4).top(ROW / 2 - 4).size(8).rounded(4).bg(dot));
  }

  // The columns `glola` prints: hash, refs, subject, age, author.
  row(row, width, t) {
    const { commit } = row;
    const merge = commit.parents.length > 1;
    return h_flex().id(commit.hash).h(ROW).w_full().items_center().gap(8).pr(12)
      .bg(this.selected === commit.hash ? t.selected : t.background).hover((e) => e.bg(t.hover))
      .child(this.graph(row, width, t))
      .child(div().flex_none().text_color(t.ansi1).child(commit.short))
      .child(h_flex().flex_1().min_w(0).gap(8).overflow_hidden()
        .children(commit.refs.map((ref) => div().flex_none().text_color(t[REF_COLORS[ref.kind]])
          .when(ref.kind === "current" || ref.kind === "head", (e) => e.font_semibold())
          .child(ref.kind === "current" ? `HEAD -> ${ref.name}` : ref.kind === "tag" ? `tag: ${ref.name}` : ref.name)))
        .child(div().truncate().text_color(merge ? t.dim : t.foreground).child(commit.subject)))
      .child(div().flex_none().w(36).text_right().text_color(t.ansi2).child(age(commit.time)))
      .child(div().flex_none().w(150).truncate().font_semibold().text_color(t.ansi4).child(commit.author));
  }

  moreRow(t) {
    return h_flex().id("more").h(ROW).w_full().items_center().px(PAD).text_color(t.accent).hover((e) => e.bg(t.hover)).child(`Load ${PAGE} more commits`);
  }

  toolbar(t) {
    const check = (id, label, on, disabled, click) => h_flex().id(id).h(24).px(8).gap(6).items_center().rounded(6).text_size(12)
      .when(!disabled, (e) => e.hover((h) => h.bg(t.hover)).on_click(click))
      .text_color(disabled ? t.dim : on ? t.foreground : t.muted)
      .child(div().size(10).rounded(2).border_1().border_color(on && !disabled ? t.accent : t.input).when(on && !disabled, (e) => e.bg(t.accent)))
      .child(label);
    return h_flex().flex_none().h(36).px(12).gap(8).items_center().border_b(1).border_color(t.border)
      .child(div().font_semibold().text_size(13).child("Git graph"))
      .child(div().flex_1().min_w(0).truncate().text_size(12).text_color(t.muted).child(this.status.root ? shorten(this.status.root) : shorten(this.folder)))
      .child(check("graph-all", "All branches", this.all, false, (_e, cx) => this.toggle("all", cx)))
      .child(check("graph-remotes", "Remotes", this.remotes, !this.all, (_e, cx) => this.toggle("remotes", cx)))
      .child(h_flex().id("graph-reload").h(24).px(8).items_center().rounded(6).text_size(12).text_color(t.muted).hover((e) => e.bg(t.hover)).on_click((_e, cx) => this.load(cx)).child("Reload"));
  }

  detailsPanel(t) {
    const commit = this.rows.find((r) => r.commit.hash === this.selected)?.commit;
    if (!commit) return null;
    const field = (label, value) => h_flex().gap(8).child(div().flex_none().w(64).text_color(t.dim).child(label)).child(div().flex_1().min_w(0).child(value));
    const date = new Date(commit.time * 1000).toLocaleString();
    const head = this.diff
      ? h_flex().id("diff-back").gap(8).text_color(t.accent).on_click((_e, cx) => { this.diff = null; cx.notify(); }).child("← Files").child(div().truncate().text_color(t.muted).child(this.diff.path))
      : div().truncate().font_semibold().child(commit.subject);
    return v_flex().flex_none().h(320).border_t(1).border_color(t.border).text_size(12)
      .child(h_flex().flex_none().h(32).px(12).gap(8).items_center().border_b(1).border_color(t.border)
        .child(div().flex_1().min_w(0).child(head))
        .child(div().id("details-close").px(6).text_color(t.dim).hover((e) => e.text_color(t.foreground)).on_click((_e, cx) => this.closeDetails(cx)).child("×")))
      .child(this.diff ? this.diffBody(t) : v_flex().id("details").flex_1().min_h(0).p(12).gap(4).overflow_y_scrollbar()
        .child(field("Commit", commit.hash))
        .child(field("Parents", commit.parents.map((p) => p.slice(0, 8)).join(" ") || "none"))
        .child(field("Author", `${commit.author} <${commit.email}>`))
        .child(field("Date", `${date} · ${age(commit.time)}`))
        .when(Boolean(this.details?.body), (e) => e.child(div().pt(6).text_color(t.muted).child(this.details.body)))
        .child(this.details ? this.fileList(t) : div().pt(6).text_color(t.dim).child("Loading files…")));
  }

  fileList(t) {
    const { files } = this.details;
    return v_flex().pt(8)
      .child(div().pb(4).text_color(t.dim).child(`${files.length} file${files.length === 1 ? "" : "s"}`))
      .children(files.map((file) => h_flex().id(`file-${file.path}`).h(22).flex_none().gap(8).px(4).items_center().rounded(4).hover((e) => e.bg(t.hover))
        .on_click((_e, cx) => this.openDiff(file.path, cx))
        .child(div().flex_1().min_w(0).truncate().child(file.path))
        .child(div().flex_none().text_color(t.ansi2).child(`+${file.added}`))
        .child(div().flex_none().text_color(t.ansi1).child(`−${file.removed}`))));
  }

  diffBody(t) {
    const color = (line) => (line.startsWith("@@") ? t.ansi6 : line.startsWith("+") ? t.ansi2 : line.startsWith("-") ? t.ansi1 : t.foreground);
    const { lines } = this.diff;
    return div().flex_1().min_h(0).relative().font_family(settings().font ?? "JetBrains Mono").text_size(11)
      .child(v_virtual_list("graph-diff", lines.length, 20, (i) => String(i), (range) => lines.slice(range.start, range.end).map((line) =>
        div().h(20).px(12).whitespace_nowrap().overflow_hidden().text_color(color(line)).child(line || " "))).size_full())
      .child(Scrollbar.vertical("graph-diff").viewport_from_layout().absolute().inset_0());
  }

  clicked(key, cx) {
    if (key === "more") this.loadMore(cx);
    else this.select(key, cx);
  }

  placeholder(t) {
    const { title, body, error } = this.status.kind === "loading" ? { title: "Loading history…" } : this.status;
    return v_flex().flex_1().min_h(0).gap(6).items_center().justify_center()
      .child(div().text_size(14).font_semibold().text_color(error ? t.ansi1 : t.foreground).child(title))
      .when(Boolean(body), (e) => e.child(div().max_w(520).text_size(12).text_center().text_color(t.muted).child(body)));
  }

  render() {
    const t = theme();
    const root = v_flex().id("git-graph").size_full().bg(t.background).text_color(t.foreground).track_focus(this.handle)
      .on_key_down((e, cx) => this.key(e, cx)).child(this.toolbar(t));
    if (this.status.kind !== "ready") return root.child(this.placeholder(t));

    const widest = this.rows.reduce((most, r) => Math.max(most, r.width), 1);
    const width = PAD * 2 + Math.min(widest, MAX_LANES) * LANE;
    const count = this.rows.length + (this.more ? 1 : 0);
    const panel = this.detailsPanel(t);
    return root
      .child(div().flex_1().min_h(0).relative().font_family(settings().font ?? "JetBrains Mono").text_size(12)
        .child(v_virtual_list("graph-rows", count, ROW, (i) => this.rows[i]?.commit.hash ?? "more", (range) => {
          const items = [];
          for (let i = range.start; i < range.end; i++) items.push(this.rows[i] ? this.row(this.rows[i], width, t) : this.moreRow(t));
          return items;
        }).size_full().on_item_click((key, cx) => this.clicked(key, cx)))
        .child(Scrollbar.vertical("graph-rows").viewport_from_layout().absolute().inset_0()))
      .when(Boolean(panel), (e) => e.child(panel));
  }
}
