# Herdr GUI (herdr-app)

Personal config for the native Herdr GUI.
The app itself is installed and updated by `update-apps herdr-app`, and the TUI config lives in the separate `herdr` package.

Only files that belong to you are tracked:

- `keys.json` - key bindings.
- `settings.json` - zoom, sounds, contrast, and the theme name.
- `themes/noctalia-tui.json` - the TUI's colors from `herdr/.config/herdr/config.toml`, on kitty's Noctalia background and ANSI palette.
  It is a snapshot, so it does not follow later Noctalia theme changes.
- `mods/sessionizer/` - opens `zsh/.config/zsh/herdr-sessionizer.sh` in its own tab on `ctrl-shift-f`, the GUI's version of the TUI's `prefix+f` popup.
  It uses a tab because commands can only give the keyboard to a pane, not to a peek or dialog.

Everything else in `~/.config/herdr-app` is written by the app, so it stays out of this package.
That includes shipped mods and layouts, which the app restores on start if edited.
To customize one, clone it with `herdr-app do layout.clone` or `herdr-app do mod.clone`, then move the clone in here and restow.

## Keys added by the mods

These mods are this repo's own code with no install step, written from the behaviour in public Herdr recipes.

| Keys | Mod | What it does |
|---|---|---|
| `Ctrl+B`, then a key | `keys.json` | The TUI's prefix keys as two-step bindings, with no popup. `Ctrl+B ?` lists them (`prefix` mod) and `Ctrl+B Ctrl+B` sends a literal `Ctrl+B`. |
| `Ctrl+Shift+G` (or `Ctrl+B g`) | `git-graph` | A live `glola`. Read-only. Click a row or press `j`/`k` for details. |
| `Ctrl+Shift+Space` | `float-space` | A floating window with its own terminals and shared notes. |
| `Ctrl+Shift+R` | `agent-resume` | Brings back agents that a reboot or core restart took from their terminals. |

- `Ctrl+B` waits for a second key, so press it twice for tmux or Claude Code's "run in background".
- `Ctrl+B ;` (`last-pane` mod) jumps between the panes you press it in, since Herdr has no last-pane command.
  The first press in a new pair of panes only remembers where you are.
- `float-space` opens with the keyboard in its header: `c` new terminal, `n`/`p` switch, `x` end, `z` size, `m` notes, `Esc` hide.
  Click a terminal to type in it, because commands can't focus a terminal in an overlay.
- `agent-resume` learns sessions from hooks.
  Claude's hook is in `agents/.claude/settings.json`.
  Codex and Antigravity keep theirs in machine-local files, so add them with `python3 ~/.config/herdr-app/mods/agent-resume/agent_resume.py install-hooks`.
  It resumes without the original launch flags, so a permission bypass is never turned back on.

## Stow notes

The app writes through these symlinks, so changing zoom in the GUI shows up as a change in this repo.
Hand edits to these files are not reliably picked up live through the symlink (seen on 0.1.11), so restart the window after editing them.
If the live file is a real file, such as after the first launch on a new machine, `make stow` reports a conflict.
Move it aside and stow again:

```bash
rm ~/.config/herdr-app/keys.json ~/.config/herdr-app/settings.json
make restow PKG=herdr-app
```

The `ctrl-alt-shift-escape` escape hatch also sets `keys.json` aside, so the same steps apply after using it.
