// Opens zsh/herdr-sessionizer.sh in its own tab, the GUI's version of the TUI's prefix+f popup.
// A tab rather than a peek or dialog: only a pane can be given the keyboard from a command.
// The tab closes when the script exits; this overlay only launches it.

import { View, div } from "gpui-kit";
import { appHome, closeOverlay, focused, hc, notify, props, run, terminals } from "herdr";

const NAME = "sessionizer";

async function launch() {
  // A tab closed mid-pick can leave the old run behind, and names are unique.
  await hc(["kill", NAME]).catch(() => null);
  await hc(["rm", NAME]).catch(() => null);

  const script = `${appHome()}/../zsh/herdr-sessionizer.sh`;
  const pane = focused()?.pane;
  const back = pane ? ["--return-pane", pane] : [];
  const started = await hc(["run", "--bg", "--json", "--no-parent", "--rm", "--name", NAME, "--", script, ...back]);
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
      run("terminal.keep", { terminal: address, place: "tab" });
      this.finish();
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
