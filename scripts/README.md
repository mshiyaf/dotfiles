# Scripts Dotfiles Package

GNU Stow package for personal CLI helpers. Everything lives under
`scripts/.local/bin/` and stows to `~/.local/bin/` (already on `$PATH`).

Install / update:

```bash
make stow-scripts     # or: make restow-scripts to pick up new files
```

## Contents

- `codex-status` — print ChatGPT/Codex usage and rate-limit status.
- `git-wt` — sibling git worktree manager (see below).

## git-wt — parallel worktrees for agentic development

Runs coding agents (opencode, Claude, etc.) in parallel without them clobbering
each other, by giving each task/branch its own isolated checkout. Worktrees are
created as a **sibling** of the main repo, never nested inside it:

```text
~/dev/github.com/you/myrepo/                 <- main worktree
~/dev/github.com/you/myrepo.worktrees/foo    <- linked worktree for branch "foo"
~/dev/github.com/you/myrepo.worktrees/bar    <- linked worktree for branch "bar"
```

Keeping them outside the repo means they never get committed, indexed, or
scanned by tooling.

### Usage

Invoke as a git subcommand (`git wt ...`) or directly (`git-wt ...`):

```bash
git wt new <branch> [<start-point>]   # create a worktree (creates branch if new)
git wt list                           # list worktrees for this repo
git wt path <branch>                  # print the worktree path
git wt rm <branch> [-D] [--force]     # remove worktree (-D also deletes branch)
git wt prune                          # prune stale worktree metadata
git wt help
```

`new` auto-detects: if the branch already exists it is attached; otherwise a new
branch is created from `<start-point>` (default: `origin/HEAD`, else current HEAD).
The base `.worktrees` directory is auto-created and auto-removed when empty.

### `wt` shell function (cd support)

An external binary cannot change the parent shell's directory, so a `wt` zsh
function in `zsh/.config/zsh/.aliasrc` wraps `git-wt` to add `cd`:

```bash
wt foo            # cd into worktree "foo" (creates it first if missing)
wt foo main       # create "foo" from main, then cd into it
wt list           # pass-through to `git wt list` (also: rm, path, prune, help)
```

### Typical agentic flow

```bash
wt feature-x                 # spin up + enter an isolated checkout
opencode                     # let an agent work here
# ... in another terminal ...
wt feature-y                 # a second agent, fully isolated
# when done:
cd ~/dev/github.com/you/myrepo
git wt rm feature-x -D       # remove worktree + branch
```
