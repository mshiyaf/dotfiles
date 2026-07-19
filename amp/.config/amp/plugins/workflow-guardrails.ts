import type { PluginAPI } from "@ampcode/plugin";

function commandSegments(command: string): string[][] {
  const segments: string[][] = [];
  let tokens: string[] = [];
  let token = "";
  let quote = "";

  const flushToken = () => {
    if (token) tokens.push(token);
    token = "";
  };
  const flushSegment = () => {
    flushToken();
    if (tokens.length) segments.push(tokens);
    tokens = [];
  };

  for (let index = 0; index < command.length; index += 1) {
    const character = command[index];
    if (quote) {
      if (character === quote) quote = "";
      else if (character === "\\" && quote === '"' && index + 1 < command.length) token += command[++index];
      else token += character;
      continue;
    }
    if (character === '"' || character === "'") {
      quote = character;
      continue;
    }
    if (character === "\\" && index + 1 < command.length) {
      if (command[index + 1] === "\n") index += 1;
      else token += command[++index];
      continue;
    }
    if (/\s/.test(character)) {
      if (character === "\n") flushSegment();
      else flushToken();
      continue;
    }
    if (character === ";" || character === "|" || character === "&") {
      flushSegment();
      if (command[index + 1] === character) index += 1;
      continue;
    }
    token += character;
  }
  flushSegment();
  return segments;
}

function executableTokens(tokens: string[]): string[] {
  let index = 0;
  while (index < tokens.length && /^[A-Za-z_][A-Za-z0-9_]*=.*/.test(tokens[index])) index += 1;
  if (tokens[index] === "command") index += 1;
  if (tokens[index] === "env") {
    index += 1;
    while (index < tokens.length && (/^[A-Za-z_][A-Za-z0-9_]*=.*/.test(tokens[index]) || tokens[index].startsWith("-"))) index += 1;
  }
  return tokens.slice(index);
}

function gitSubcommand(tokens: string[]): { name: string; args: string[] } | null {
  if (tokens[0] !== "git") return null;
  let index = 1;
  while (index < tokens.length && tokens[index].startsWith("-")) {
    const option = tokens[index++];
    if (["-C", "-c", "--git-dir", "--work-tree", "--namespace"].includes(option)) index += 1;
  }
  return index < tokens.length ? { name: tokens[index], args: tokens.slice(index + 1) } : null;
}

function hasShortFlag(args: string[], flag: string) {
  return args.some((arg) => arg.startsWith("-") && !arg.startsWith("--") && arg.slice(1).includes(flag));
}

function directCommandReason(tokens: string[]): string | null {
  const executable = executableTokens(tokens);
  if (!executable.length) return null;

  const [programPath, ...args] = executable;
  const program = programPath.split("/").at(-1) || programPath;
  executable[0] = program;
  if (program === "sudo") return "runs with elevated privileges";

  if (["bash", "sh", "zsh"].includes(program)) {
    const commandIndex = args.findIndex((arg) => arg === "-c" || arg === "--command");
    if (commandIndex >= 0 && args[commandIndex + 1]) return blockedCommandReason(args[commandIndex + 1]);
  }

  const git = gitSubcommand(executable);
  if (git?.name === "push") return "publishes commits to a remote";
  if (git?.name === "reset" && git.args.includes("--hard")) return "can discard local work";
  if (git?.name === "branch") {
    const deletes = git.args.includes("-D") || git.args.includes("--delete") || hasShortFlag(git.args, "d");
    const forces = git.args.includes("-D") || git.args.includes("--force") || hasShortFlag(git.args, "f");
    if (deletes && forces) return "force-deletes a branch";
  }
  if (git?.name === "clean") {
    const dryRun = git.args.includes("--dry-run") || hasShortFlag(git.args, "n");
    const force = git.args.includes("--force") || hasShortFlag(git.args, "f");
    if (force && !dryRun) return "can delete untracked files";
  }

  if (program === "rm") {
    const recursive = args.includes("--recursive") || hasShortFlag(args, "r") || hasShortFlag(args, "R");
    const force = args.includes("--force") || hasShortFlag(args, "f");
    const targets = args.filter((arg) => !arg.startsWith("-"));
    const targetsRoot = targets.some((target) =>
      target === "/" || target === "~" || target.startsWith("~/") || target === "$HOME" ||
      target.startsWith("$HOME/") || target === "${HOME}" || target.startsWith("${HOME}/")
    );
    if (recursive && force && targetsRoot) return "recursively deletes files from a root or home path";
  }

  return null;
}

export function blockedCommandReason(command: string): string | null {
  for (const segment of commandSegments(command)) {
    const reason = directCommandReason(segment);
    if (reason) return reason;
  }
  return null;
}

async function reportHerdr(state: "idle" | "working" | "blocked") {
  if (!herdrReportingEnabled()) return;

  const binary = process.env.HERDR_BIN_PATH || "herdr";
  try {
    const processHandle = Bun.spawn(
      [
        binary,
        "pane",
        "report-agent",
        process.env.HERDR_PANE_ID,
        "--source",
        "custom:amp-plugin",
        "--agent",
        "amp",
        "--state",
        state,
      ],
      { stdout: "ignore", stderr: "ignore" },
    );
    await processHandle.exited;
  } catch {
    // Agent-state reporting is observability only and must never block Amp.
  }
}

type HerdrState = "idle" | "working" | "blocked";

export function herdrReportingEnabled(env: Record<string, string | undefined> = process.env) {
  return env.CREW_MANAGED !== "1" && env.HERDR_ENV === "1" && Boolean(env.HERDR_PANE_ID);
}

export function createLifecycleReporter(report: (state: HerdrState) => Promise<void> = reportHerdr) {
  const activeTurns = new Set<string>();
  let reportChain = Promise.resolve();
  const queueReport = (state: HerdrState) => {
    reportChain = reportChain.then(() => report(state));
    return reportChain;
  };

  return {
    start(threadID: string, turnID: string) {
      activeTurns.add(`${threadID}:${turnID}`);
      return queueReport("working");
    },
    end(threadID: string, turnID: string, status: "done" | "error" | "cancelled") {
      activeTurns.delete(`${threadID}:${turnID}`);
      if (status !== "done") return queueReport("blocked");
      return queueReport(activeTurns.size ? "working" : "idle");
    },
  };
}

export default function workflowGuardrails(amp: PluginAPI) {
  const lifecycle = createLifecycleReporter();

  amp.on("agent.start", async (event) => {
    await lifecycle.start(event.thread.id, event.id);
  });

  amp.on("agent.end", async (event) => {
    await lifecycle.end(event.thread.id, event.id, event.status);
  });

  amp.on("tool.call", async (event, ctx) => {
    const shell = amp.helpers.shellCommandFromToolCall(event);
    if (!shell?.command) return { action: "allow" };

    const reason = blockedCommandReason(shell.command);
    if (!reason) return { action: "allow" };

    const active = amp.activeThread.current?.id === event.thread.id;
    if (active) {
      try {
        const confirmed = await ctx.ui.confirm({
          title: "Potentially destructive or outward-facing command",
          message: `${shell.command}\n\nThis command ${reason}.`,
          confirmButtonText: "Allow once",
        });
        if (confirmed) return { action: "allow" };
      } catch {
        // Execute-mode and background threads have no interactive approval surface.
      }
    }

    return {
      action: "reject-and-continue",
      message: `Blocked command because it ${reason}: ${shell.command}`,
    };
  });
}
