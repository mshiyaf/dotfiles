import { afterEach, describe, expect, test } from "bun:test";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const script = path.resolve(import.meta.dir, "../scripts/.local/bin/ai-account");
const claudeStatusline = path.resolve(import.meta.dir, "../scripts/.local/bin/claude-statusline");
const temporaryDirectories: string[] = [];

function workspace() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "ai-account-test-"));
  temporaryDirectories.push(root);
  return {
    root,
    home: path.join(root, "home"),
    accounts: path.join(root, "accounts"),
  };
}

function run(home: string, accounts: string, ...arguments_: string[]) {
  return Bun.spawnSync([script, ...arguments_], {
    env: { ...process.env, HOME: home, AI_ACCOUNT_HOME: accounts },
    stdout: "pipe",
    stderr: "pipe",
  });
}

function claudeCredential(token: string) {
  return { claudeAiOauth: { accessToken: `${token}-access`, refreshToken: `${token}-refresh` } };
}

function codexCredential(token: string) {
  return { auth_mode: "chatgpt", tokens: { access_token: `${token}-access`, refresh_token: `${token}-refresh` } };
}

function writeJson(file: string, value: unknown) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(value));
}

afterEach(() => {
  for (const directory of temporaryDirectories.splice(0)) fs.rmSync(directory, { recursive: true, force: true });
});

describe("ai-account", () => {
  test.each([
    ["claude", ".claude/.credentials.json", claudeCredential],
    ["codex", ".codex/auth.json", codexCredential],
  ] as const)("switches %s credentials and preserves refreshed active credentials", (provider, livePath, credential) => {
    const { home, accounts } = workspace();
    const live = path.join(home, livePath);

    writeJson(live, credential("personal"));
    expect(run(home, accounts, "save", provider, "personal").exitCode).toBe(0);
    writeJson(live, credential("work"));
    expect(run(home, accounts, "save", provider, "work").exitCode).toBe(0);
    expect(run(home, accounts, "switch", provider, "personal").exitCode).toBe(0);
    expect(JSON.parse(fs.readFileSync(live, "utf8"))).toEqual(credential("personal"));

    writeJson(live, credential("personal-refreshed"));
    expect(run(home, accounts, "switch", provider, "work").exitCode).toBe(0);
    expect(JSON.parse(fs.readFileSync(live, "utf8"))).toEqual(credential("work"));
    expect(JSON.parse(fs.readFileSync(path.join(accounts, provider, "personal.json"), "utf8"))).toEqual(
      credential("personal-refreshed"),
    );
    expect(fs.statSync(live).mode & 0o777).toBe(0o600);
  });

  test("rejects a malformed profile without replacing live credentials", () => {
    const { home, accounts } = workspace();
    const live = path.join(home, ".claude/.credentials.json");
    writeJson(live, claudeCredential("current"));
    writeJson(path.join(accounts, "claude/broken.json"), { nope: true });

    const result = run(home, accounts, "switch", "claude", "broken");
    expect(result.exitCode).toBe(1);
    expect(result.stderr.toString()).toContain("not valid for this provider");
    expect(JSON.parse(fs.readFileSync(live, "utf8"))).toEqual(claudeCredential("current"));
  });

  test("shows the active Claude profile in the Claude status line", () => {
    const { home, accounts } = workspace();
    writeJson(path.join(home, ".claude/.credentials.json"), claudeCredential("work"));
    expect(run(home, accounts, "save", "claude", "work").exitCode).toBe(0);

    const result = Bun.spawnSync([claudeStatusline], {
      env: { ...process.env, HOME: home, AI_ACCOUNT_HOME: accounts },
      stdin: new Blob([JSON.stringify({ model: { display_name: "Claude" }, cwd: home })]),
      stdout: "pipe",
      stderr: "pipe",
    });
    expect(result.exitCode).toBe(0);
    expect(result.stdout.toString()).toContain("acct:work");
  });
});
