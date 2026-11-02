// Ctrl+Shift+R: bring back agents that a reboot or core restart took from their terminals.
// The work is in agent_resume.py; this popup runs it and reports the result.

import { View, div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { appHome, closeOverlay, exec, notify, props, theme } from "herdr";

const SPIN = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

function plural(n) {
  return `${n} agent${n === 1 ? "" : "s"}`;
}

function summary({ busy, resumed = [], problems = [] }) {
  if (busy) return { title: "Already resuming agents", level: "info", timeout: 3000 };
  const body = problems.join("; ");
  if (resumed.length && problems.length) {
    return { title: `Resumed ${resumed.length} of ${plural(resumed.length + problems.length)}`, body: `Not resumed: ${body}`, level: "warning", timeout: 8000 };
  }
  if (resumed.length) return { title: `Resumed ${plural(resumed.length)}`, body: resumed.join(", "), level: "success", timeout: 5000 };
  if (problems.length) return { title: `Couldn't resume ${plural(problems.length)}`, body, level: "warning", timeout: 8000 };
  return { title: "No agent to resume", body: "No terminal lost its agent.", level: "info", timeout: 3000 };
}

export default class AgentResume extends View {
  init(_props, cx) {
    cx.spawn(async () => {
      try {
        const result = await exec("python3", [`${appHome()}/mods/agent-resume/agent_resume.py`, "resume"]);
        if (result.code !== 0) throw new Error(result.stderr || `exited ${result.code}`);
        notify(summary(JSON.parse(result.stdout)));
      } catch (error) {
        notify({ title: "Couldn't resume agents", body: String(error), level: "error" });
      } finally {
        if (props()?.overlay) closeOverlay(props().overlay);
      }
    });
  }

  render() {
    const t = theme();
    return h_flex().size_full().items_center().gap(10).px(14).rounded(10).border_1()
      .bg(t.popover).border_color(t.border).text_color(t.foreground).text_size(12)
      .child(div().frames(SPIN, 80).text_color(t.accent))
      .child(div().truncate().child("Resuming agents…"));
  }
}
