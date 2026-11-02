// Opens zsh/herdr-sessionizer.sh in a popup, like the TUI's prefix+f.
// A dialog hands the keyboard to its terminal as it opens, but closing any overlay gives
// the keyboard back to the top dialog's frame. So this launcher must close before the
// dialog opens, or the terminal loses it. The dialog closes when the script exits.

import { View, div } from "gpui-kit";
import { appHome, closeOverlay, hc, notify, openOverlay, props, terminals } from "herdr";

const NAME = "sessionizer";

async function launch() {
  // A popup dismissed mid-pick can leave the old run behind, and names are unique.
  await hc(["kill", NAME]).catch(() => null);
  await hc(["rm", NAME]).catch(() => null);

  const script = `${appHome()}/../zsh/herdr-sessionizer.sh`;
  const started = await hc(["run", "--bg", "--json", "--no-parent", "--rm", "--name", NAME, "--", script]);
  if (started.code !== 0) throw new Error(started.stderr || `hc run exited ${started.code}`);
  return JSON.parse(started.stdout).address;
}

export default class Sessionizer extends View {
  init(_props, cx) {
    this.overlay = props()?.overlay;
    cx.spawn(async (cx) => {
      try {
        this.openWhenKnown(await launch(), 0, cx);
      } catch (error) {
        this.fail(String(error));
      }
    });
  }

  // The window learns about a new terminal a moment after hc starts it.
  openWhenKnown(address, tries, cx) {
    if (terminals().some((t) => t.address === address)) {
      this.finish();
      openOverlay({
        kind: "dialog",
        key: NAME,
        modal: true,
        width: 0.85,
        height: 0.75,
        layout: { type: "column", children: [{ type: "block", content: { terminal: address } }] },
      });
    } else if (tries < 50) {
      cx.timer.after(100, (cx) => this.openWhenKnown(address, tries + 1, cx));
    } else {
      this.fail(`terminal ${address} never appeared`);
    }
  }

  fail(body) {
    notify({ title: "Sessionizer failed", body, level: "error" });
    this.finish();
  }

  finish() {
    if (this.overlay) closeOverlay(this.overlay);
  }

  render() {
    return div();
  }
}
