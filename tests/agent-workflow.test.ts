import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

import workflowGuardrails, {
  blockedCommandReason,
  createLifecycleReporter,
  herdrReportingEnabled,
} from "../amp/.config/amp/plugins/workflow-guardrails";

const repo = resolve(import.meta.dir, "..");

describe("Amp workflow guardrails", () => {
  test.each([
    "git push origin main",
    "/usr/bin/git push origin main",
    "git -C /tmp/repo push origin feature",
    "git reset --hard HEAD~1",
    "git clean -fdx",
    "git branch -D feature",
    "git branch --delete --force feature",
    "git branch -df feature",
    "git --no-pager push origin main",
    String.raw`g\it push origin main`,
    String.raw`git pu\sh origin main`,
    "sudo apt install package",
    String.raw`s\udo apt install package`,
    "/usr/bin/sudo apt install package",
    "rm -rf /",
    'rm -fr "/"',
    "rm -r -f $HOME",
    'rm --recursive --force "$HOME/cache"',
    "bash -c 'git push origin main'",
    "printf ok && git push origin main",
  ])("blocks %s", (command) => {
    expect(blockedCommandReason(command)).not.toBeNull();
  });

  test.each([
    "git status --short",
    "git diff --check",
    "git clean -nfd",
    "rm -rf ./build",
    "rg sudo docs",
    "printf '%s\\n' 'git push origin main'",
    "bun test",
  ])("allows %s", (command) => {
    expect(blockedCommandReason(command)).toBeNull();
  });
});

describe("Amp plugin integration", () => {
  test("registers shell policy for both shell tool shapes", async () => {
    let toolHandler: ((event: any, context: any) => Promise<any>) | undefined;
    const amp = {
      on(event: string, handler: any) {
        if (event === "tool.call") toolHandler = handler;
      },
      helpers: {
        shellCommandFromToolCall(event: any) {
          const command = event.input.command ?? event.input.cmd;
          return command ? { command } : null;
        },
      },
      activeThread: { current: null },
    };
    workflowGuardrails(amp as any);

    const context = { ui: { confirm: () => Promise.resolve(false) } };
    for (const [tool, input] of [
      ["shell_command", { command: "git push origin main" }],
      ["Bash", { cmd: "git branch --delete --force feature" }],
    ] as const) {
      const result = await toolHandler?.(
        { toolUseID: "tool-test", tool, input, thread: { id: "thread-test" } },
        context,
      );
      expect(result?.action).toBe("reject-and-continue");
    }
  });

  test("serializes overlapping Herdr lifecycle reports", async () => {
    const reports: string[] = [];
    let releaseFirst: (() => void) | undefined;
    const firstReport = new Promise<void>((resolve) => {
      releaseFirst = resolve;
    });
    let calls = 0;
    const lifecycle = createLifecycleReporter(async (state) => {
      calls += 1;
      if (calls === 1) await firstReport;
      reports.push(state);
    });

    const first = lifecycle.start("thread-a", "turn-a");
    const second = lifecycle.start("thread-b", "turn-b");
    const firstEnd = lifecycle.end("thread-a", "turn-a", "done");
    const secondEnd = lifecycle.end("thread-b", "turn-b", "done");
    expect(reports).toEqual([]);
    releaseFirst?.();
    await Promise.all([first, second, firstEnd, secondEnd]);
    expect(reports).toEqual(["working", "working", "working", "idle"]);
  });

  test("leaves Crew-managed Herdr panes to the Crew reporter", () => {
    expect(herdrReportingEnabled({ HERDR_ENV: "1", HERDR_PANE_ID: "w1:p1", CREW_MANAGED: "1" })).toBe(false);
    expect(herdrReportingEnabled({ HERDR_ENV: "1", HERDR_PANE_ID: "w1:p1" })).toBe(true);
  });
});

describe("Crew Amp execution", () => {
  const crew = readFileSync(resolve(repo, "scripts/.local/bin/crew"), "utf8");
  const callCrewFunction = (body: string) => {
    const result = Bun.spawnSync(["bash", "-c", `source "$1"; ${body}`, "test", resolve(repo, "scripts/.local/bin/crew")]);
    expect(result.exitCode).toBe(0);
    return result.stdout.toString();
  };

  test("streams concise Claude activity without thinking or tool results", () => {
    const events = [
      { type: "system", subtype: "init" },
      {
        type: "assistant",
        message: {
          content: [
            { type: "thinking", thinking: "private reasoning" },
            { type: "text", text: "I am checking the migration." },
            { type: "tool_use", name: "Bash", input: { description: "Run focused database tests", command: "bun test" } },
            { type: "tool_use", name: "Edit", input: { file_path: "src/store.ts" } },
          ],
        },
      },
      { type: "user", message: { content: [{ type: "tool_result", content: "very long output" }] } },
      { type: "result", subtype: "success", result: "Finished" },
    ];
    const input = events.map((event) => JSON.stringify(event)).join("\n");
    const encoded = Buffer.from(input).toString("base64");
    const output = callCrewFunction(`printf %s '${encoded}' | base64 -d | claude_stream_filter`);

    expect(output).toBe([
      "[started] Claude session",
      "[agent] I am checking the migration.",
      "[Bash] Run focused database tests",
      "[Edit] src/store.ts",
      "[done] Claude finished",
      "",
    ].join("\n"));
    expect(output).not.toContain("private reasoning");
    expect(output).not.toContain("very long output");
  });

  test("launches Claude with realtime streaming output", () => {
    const command = callCrewFunction("claude_headless_command sonnet 'finish task'");
    expect(command).toContain("claude -p --model sonnet");
    expect(command).toContain("--output-format stream-json --verbose");
    expect(command).toContain("jq --unbuffered");
    expect(command).toContain("set -o pipefail");
  });

  test("uses execute mode for Amp headless runs", () => {
    const command = callCrewFunction("amp_headless_command medium 'finish task'");
    expect(command).toContain("CREW_MANAGED=1 amp --settings-file");
    expect(command).toContain("--plugin-ready-timeout 10 -x");
  });

  test("runs every tasked Herdr crewmate headlessly", () => {
    for (const engine of ["amp", "opencode", "claude", "codex", "kimi"]) {
      expect(callCrewFunction(`should_run_headless task && printf ${engine}`)).toBe(engine);
    }
  });

  test("maps the deep Amp profile to high", () => {
    expect(callCrewFunction("resolve_profile deep amp")).toBe("high");
  });

  test("does not apply unattended settings to interactive Amp", () => {
    const command = callCrewFunction("amp_interactive_command medium");
    expect(command).toBe("amp -m medium");
    expect(command).not.toContain("--settings-file");
    expect(callCrewFunction("should_run_headless '' || printf interactive")).toBe("interactive");
  });

  test("reports failed Herdr crewmates as blocked", () => {
    expect(crew).toContain("[ \\$rc -eq 0 ] || state=blocked");
  });

  test("fails closed when the deployed Amp plugin is missing", () => {
    const emptyHome = resolve(repo, ".tmp-missing-amp-plugin");
    const result = Bun.spawnSync(
      ["bash", "-c", 'source "$1"; require_amp_guard', "test", resolve(repo, "scripts/.local/bin/crew")],
      { env: { ...process.env, HOME: emptyHome }, stdout: "pipe", stderr: "pipe" },
    );
    expect(result.exitCode).not.toBe(0);
    expect(result.stderr.toString()).toContain("Amp workflow guard plugin not found");

    const gateResult = Bun.spawnSync(
      ["bash", "-c", 'source "$1"; require_amp_guard', "test", resolve(repo, "scripts/.local/bin/gate")],
      { env: { ...process.env, HOME: emptyHome }, stdout: "pipe", stderr: "pipe" },
    );
    expect(gateResult.exitCode).not.toBe(0);
    expect(gateResult.stderr.toString()).toContain("Amp workflow guard plugin not found");
  });
});
