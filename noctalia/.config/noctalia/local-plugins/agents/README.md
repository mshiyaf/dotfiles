# Agents

Noctalia v5 plugin modelled on the Omarchy Quattro agents menu.
It shows quota usage for Claude Code, Codex, Amp, and Command Code, switches saved accounts, and lists live agent sessions.

## Features

- Bar: tiny session meters for the live Claude and Codex accounts (or a single robot icon), with a summary tooltip.
- Quota bars with a pace tick at the elapsed share of the window.
  The line under each live bar gives the percentage used, how far ahead of or under pace you are, and either a forecast ("limit in ~2d 0h") or the reset time.
- Notifications when a live window crosses 75%, 90%, or its limit, and when a window you pushed past 75% resets.
- Accounts from the `ai-account` store: the live one is marked ACTIVE, others offer Use (click twice to confirm) or Sign in.
- Codex free reset credits and their next expiry.
- Amp plan budget and credits, and Command Code windows, credits, and renewal.
- Amp model routing: each linked ChatGPT subscription with its Codex usage, and buttons to hand GPT models to Amp's own plan or back.
  With auto-failover on, a used-up link is deactivated and restored when its window resets; a manual choice pauses that until then.
- Live sessions from herdr with their status; clicking one focuses the pane and raises its terminal window.
- `+` opens the agent command in a terminal.
- The panel floats near the bar icon, like the control center.

## How it works

`usage.py` (stdlib only, run with the system `python3`) prints one JSON snapshot:

- Claude limits from `api.anthropic.com/api/oauth/usage`; Codex limits and reset credits from `chatgpt.com/backend-api/wham/*`.
- Amp from `amp usage`; Command Code from `api.commandcode.ai/alpha/billing/*`.
- Tokens today from `~/.claude/projects` and `~/.codex/sessions`, with a per-file cache.
- Sessions from `herdr agent list`.

The live login of each CLI is never refreshed or rewritten here.
Inactive saved profiles are refreshed when expired, under the same lock `ai-account` takes, so a background refresh cannot race a switch.
The active Codex profile is matched by account ID, so a switch made in the ChatGPT app is still recognised.

`service.luau` runs the helper every few minutes, persists the last snapshot, and sends notifications; `widget.luau` and `panel.luau` only render.

## Account switching

Switching runs `ai-account switch <provider> <profile>`.
For Codex it stops the shared app-server daemon before swapping `auth.json` and starts it again afterwards; the daemon otherwise keeps the old login in memory and can write it back.
That restart interrupts running Codex CLI sessions, which is why the panel asks for confirmation.

## Install

The `noctalia` stow package links this directory to `~/.config/noctalia/local-plugins/agents`.
`plugins.toml` declares the `local` path source and enables `mshiyaf/agents`.
If the GUI state file already overrides `[plugins]`, register it once at runtime:

```sh
noctalia msg plugins source add local path ~/.config/noctalia/local-plugins
noctalia msg plugins enable mshiyaf/agents
```

Panels do not hot-reload; after editing `panel.luau` or `plugin.toml`, disable and re-enable the plugin.

Brand marks in `assets/` come from [lobehub/lobe-icons](https://github.com/lobehub/lobe-icons) (MIT).
