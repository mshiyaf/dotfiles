// Ctrl+B ;: jump between the pane you press it in and the pane you last pressed it in.
// Herdr has no last-pane command and a mod only runs when opened, so moves made between
// presses aren't seen: the first press in a new pair of panes only remembers where you are.

import { View, div } from "gpui-kit";
import { closeOverlay, focused, panes, props, run, setShared, shared } from "herdr";

const LAST = "last-pane.pane";

export default class LastPane extends View {
  init() {
    const here = focused()?.pane;
    const target = shared(LAST);
    if (here) setShared(LAST, here);
    if (target && target !== here && panes().some((p) => p.pane === target)) run("pane.focus", { pane: target });
    if (props()?.overlay) closeOverlay(props().overlay);
  }

  render() {
    return div();
  }
}
