// Ctrl+B, then a key: the Herdr TUI's prefix bindings, with a hint while you decide.
// Behaviour follows Herdr's "Tmux prefix" example recipe, with the TUI's keys.

import { View, div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { closeOverlay, focused, hc, nextCommand, panes, props, run, setShared, shared, theme } from "herdr";

const REPEAT_MS = 500;
const LAST = "prefix.panes";

// [key, label, command, args, repeatable, shown only in the full list]
const BINDINGS = [
  ["c", "New tab", "tab.new"],
  ["n", "Next tab", "tab.next", {}, true],
  ["p", "Previous tab", "tab.prev", {}, true],
  ["T", "Rename tab", "tab.rename"],
  ["X", "Close tab", "tab.close"],
  ["v", "Split right", "pane.split", { direction: "right" }],
  ["-", "Split down", "pane.split", { direction: "down" }],
  ["x", "Close pane", "pane.close"],
  ["z", "Zoom pane", "pane.zoom"],
  ["h", "Focus left", "pane.go", { direction: "left" }, true],
  ["j", "Focus down", "pane.go", { direction: "down" }, true],
  ["k", "Focus up", "pane.go", { direction: "up" }, true],
  ["l", "Focus right", "pane.go", { direction: "right" }, true],
  [";", "Last pane", "last-pane"],
  ["J", "Next space", "space.next", {}, true],
  ["K", "Previous space", "space.prev", {}, true],
  ["N", "New space", "space.new"],
  ["W", "Rename space", "space.rename"],
  ["D", "Close space", "space.close"],
  ["w", "Go to", "mod.open", { name: "picker" }],
  ["f", "Sessionizer", "mod.open", { name: "sessionizer" }],
  ["g", "Git graph", "mod.open", { name: "git-graph" }],
  ["b", "Toggle sidebar", "layout.toggle", { id: "sidebar" }],
  ["s", "Settings", "app.settings"],
  ["left", "Focus left", "pane.go", { direction: "left" }, true, true],
  ["down", "Focus down", "pane.go", { direction: "down" }, true, true],
  ["up", "Focus up", "pane.go", { direction: "up" }, true, true],
  ["right", "Focus right", "pane.go", { direction: "right" }, true, true],
  ...Array.from({ length: 9 }, (_, i) => [String(i + 1), `Tab ${i + 1}`, "tab.select", { index: i + 1 }, false, true]),
];

// Herdr has no last-pane command, so remember the pane seen at each prefix press.
// Moving with Alt+H and friends is still caught: the next press sees a new pane.
function notePane() {
  const pane = focused()?.pane;
  const seen = shared(LAST) ?? {};
  if (pane && pane !== seen.current) setShared(LAST, { current: pane, previous: seen.current ?? null });
}

function lastPane() {
  const { current, previous } = shared(LAST) ?? {};
  if (!previous || !panes().some((p) => p.pane === previous)) return;
  setShared(LAST, { current: previous, previous: current });
  run("pane.focus", { pane: previous });
}

function typedKey(e) {
  if (e.modifiers.shift && e.key.length === 1) return e.key_char ?? e.key.toUpperCase();
  return e.key_char && e.key.length === 1 ? e.key_char : e.key;
}

export default class Prefix extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.handle.focus();
    this.repeat = false;
    this.generation = 0;
    this.all = false;
    notePane();
    // keys.json's mod:prefix section: Ctrl+B would otherwise reopen this popup.
    cx.spawn(async (cx) => {
      for (;;) {
        await nextCommand();
        this.sendPrefix(cx);
      }
    });
  }

  dismiss() {
    closeOverlay(props().overlay);
  }

  sendPrefix(cx) {
    const terminal = focused()?.terminal;
    if (terminal) {
      // hc starts its process at the call, so closing this view doesn't cancel it.
      const sent = hc(["keys", terminal, "ctrl+b"]);
      cx.spawn(async () => { await sent; });
    }
    this.dismiss();
  }

  key(e, cx) {
    cx.stop_propagation();
    const { control, alt, platform } = e.modifiers;
    if (e.key === "escape") return this.dismiss();
    if (control && e.key === "b") return this.sendPrefix(cx);
    if (control || alt || platform) return this.dismiss();

    const key = typedKey(e);
    if (key === "?") {
      this.all = !this.all;
      this.repeat = false;
      this.generation++;
      cx.notify();
      return;
    }
    const binding = BINDINGS.find((b) => b[0] === key);
    if (!binding) return this.dismiss();

    const [, , command, args = {}, repeatable = false] = binding;
    if (!repeatable) this.dismiss();
    // Tab can't be bound here: the window takes it for focus movement before any mod sees it.
    if (command === "last-pane") lastPane();
    else run(command, args);
    if (!repeatable) return;

    this.repeat = true;
    const generation = ++this.generation;
    cx.timer.after(REPEAT_MS, () => {
      if (this.generation === generation) this.dismiss();
    });
    cx.notify();
  }

  render() {
    const t = theme();
    const rows = BINDINGS.filter((b) => this.all || !b[5]);
    return v_flex().id("prefix").track_focus(this.handle)
      .on_key_down((e, cx) => this.key(e, cx))
      .p(14).gap(8).bg(t.popover).text_color(t.foreground).text_size(12)
      .child(h_flex().justify_between()
        .child(div().font_semibold().child(this.repeat ? `Repeat · ${REPEAT_MS} ms` : "Ctrl+B · waiting for a key"))
        .child(div().text_color(t.muted).child("Esc cancel · ^B send prefix")))
      .child(v_flex().id("prefix-keys").h(340).flex_none().overflow_y_scrollbar().children(rows.map(([key, label, , , repeatable]) =>
        h_flex().h(20).flex_none().items_center().gap(12)
          .child(div().w(44).text_color(t.accent).child(key))
          .child(div().flex_1().child(label))
          .child(div().text_color(t.dim).child(repeatable ? "repeat" : "")))))
      .child(div().text_color(t.muted).child(this.all ? "? fewer bindings" : "? all bindings"));
  }
}
