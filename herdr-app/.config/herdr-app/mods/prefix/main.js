// Ctrl+B ?: lists the Ctrl+B keys. The keys themselves are two-step bindings in keys.json, so
// nothing opens when you use them and fast typing can't outrun anything. Any key closes this.

import { View, div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { appHome, closeOverlay, props, theme } from "herdr";
import { readFile } from "fs/promises";

const PREFIX = "ctrl-b ";

export default class Prefix extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.handle.focus();
    this.rows = [];
    cx.spawn(async (cx) => {
      const keys = JSON.parse(await readFile(`${appHome()}/keys.json`, "utf8"));
      this.rows = Object.entries(keys.terminal).filter(([key]) => key.startsWith(PREFIX)).map(([key, action]) => [key.slice(PREFIX.length), action]);
      cx.notify();
    });
  }

  render() {
    const t = theme();
    return v_flex().id("prefix").track_focus(this.handle)
      .on_key_down((_e, cx) => { cx.stop_propagation(); closeOverlay(props().overlay); })
      .p(14).gap(8).bg(t.popover).text_color(t.foreground).text_size(12)
      .child(h_flex().justify_between()
        .child(div().font_semibold().child("Ctrl+B, then"))
        .child(div().text_color(t.muted).child("Any key closes")))
      .child(v_flex().id("prefix-keys").h(370).flex_none().overflow_y_scrollbar().children(this.rows.map(([key, action]) =>
        h_flex().h(20).flex_none().items_center().gap(12)
          .child(div().w(70).text_color(t.accent).child(key))
          .child(div().flex_1().text_color(t.muted).child(action)))));
  }
}
