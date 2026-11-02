import { describe, expect, mock, test } from "bun:test";

// The mod runs inside Herdr, so stand in for the modules only Herdr provides.
mock.module("gpui-kit", () => ({ div: () => {}, PathBuilder: {}, View: class {} }));
mock.module("gpui-base", () => ({ h_flex: () => {}, Scrollbar: {}, v_flex: () => {}, v_virtual_list: () => {} }));
mock.module("herdr", () => ({ closeOverlay() {}, exec() {}, focused() {}, home() {}, panes() {}, props() {}, settings() {}, spaces() {}, theme() {}, watchFolder() {} }));

const { age, layoutLanes, logArgs, parseLog, parseNumstat, parseRefs } = await import("../herdr-app/.config/herdr-app/mods/git-graph/main.js");

const commit = (hash: string, ...parents: string[]) => ({ hash, parents });

describe("git graph lanes", () => {
  test("a straight history stays in one lane", () => {
    const rows = layoutLanes([commit("c", "b"), commit("b", "a"), commit("a")]);
    expect(rows.map((r) => r.lane)).toEqual([0, 0, 0]);
    expect(rows[2].segments).toEqual([[0, 0, 0, 0.5, 0]]);
  });

  test("a merge opens a lane for its second parent and it closes at the fork", () => {
    const rows = layoutLanes([commit("m", "a", "b"), commit("b", "base"), commit("a", "base"), commit("base")]);
    expect(rows.map((r) => r.lane)).toEqual([0, 1, 0, 0]);
    expect(rows[0].segments).toContainEqual([0, 0.5, 1, 1, 1]);
    // Both lanes wait for the base, and lane 1 curves into it.
    expect(rows[3].segments).toContainEqual([1, 0, 0, 0.5, 1]);
    expect(rows[3].width).toBe(1);
  });

  test("branch tips that aren't reached yet take free lanes", () => {
    const rows = layoutLanes([commit("x", "base"), commit("y", "base"), commit("base")]);
    expect(rows.map((r) => r.lane)).toEqual([0, 1, 0]);
  });

  test("a closed lane is reused", () => {
    const rows = layoutLanes([commit("x", "base"), commit("y", "base"), commit("base", "root"), commit("z", "root"), commit("root")]);
    expect(rows[3].lane).toBe(1);
  });
});

describe("git graph parsing", () => {
  test("reads refs as git decorates them", () => {
    expect(parseRefs("HEAD -> main, tag: v1, origin/main, feat")).toEqual([
      { kind: "current", name: "main" },
      { kind: "tag", name: "v1" },
      { kind: "remote", name: "origin/main" },
      { kind: "branch", name: "feat" },
    ]);
    expect(parseRefs("")).toEqual([]);
  });

  test("reads log records, including a root commit", () => {
    const record = (...fields: string[]) => `${fields.join("\0")}\x01\n`;
    const [first, root] = parseLog(record("aaaa", "aa", "bbbb", "HEAD -> main", "Me", "me@x", "100", "subject one") + record("bbbb", "bb", "", "", "Me", "me@x", "90", "root"));
    expect(first).toMatchObject({ hash: "aaaa", short: "aa", parents: ["bbbb"], author: "Me", time: 100, subject: "subject one" });
    expect(root).toMatchObject({ hash: "bbbb", parents: [], refs: [], subject: "root" });
  });

  test("All branches is glola and Current is glol", () => {
    expect(logArgs({ all: true, remotes: true, limit: 300 })).toContain("--all");
    expect(logArgs({ all: true, remotes: false, limit: 300 })).toContain("--exclude=refs/remotes/*");
    expect(logArgs({ all: false, remotes: true, limit: 300 })).toContain("HEAD");
    expect(logArgs({ all: false, remotes: true, limit: 300 })).not.toContain("--all");
  });

  test("shortens ages and reads numstat", () => {
    expect([age(1000, 1030), age(1000, 1000 + 120), age(1000, 1000 + 7200), age(1000, 1000 + 86400 * 3)]).toEqual(["now", "2m", "2h", "3d"]);
    expect(parseNumstat("1\t2\tsrc/a b.js\n-\t-\timg.png\n")).toEqual([
      { added: "1", removed: "2", path: "src/a b.js" },
      { added: "-", removed: "-", path: "img.png" },
    ]);
  });
});
