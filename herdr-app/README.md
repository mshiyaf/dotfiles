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

The app writes through these symlinks, so changing zoom in the GUI shows up as a change in this repo.
Hand edits to these files are not reliably picked up live through the symlink (seen on 0.1.11), so restart the window after editing them.
If the live file is a real file, such as after the first launch on a new machine, `make stow` reports a conflict.
Move it aside and stow again:

```bash
rm ~/.config/herdr-app/keys.json ~/.config/herdr-app/settings.json
make restow PKG=herdr-app
```

The `ctrl-alt-shift-escape` escape hatch also sets `keys.json` aside, so the same steps apply after using it.
