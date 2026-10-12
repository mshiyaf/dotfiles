# Default applications (mimeapps)

`~/.config/mimeapps.list` - which app opens each file type and URL scheme.
Stowed as a symlink by `make stow` (it's in `DEFAULT_PACKAGES`).

Change defaults with `xdg-mime`, which follows the symlink and edits this file in place:

```bash
xdg-mime default mpv.desktop audio/ogg
xdg-mime query default audio/ogg
```

GUI "Open With → set as default" dialogs (GLib/GIO apps such as Nautilus) save by replacing the file, which turns the symlink back into a plain file.
After using one, copy the result back here and restow:

```bash
cp ~/.config/mimeapps.list mimeapps/.config/mimeapps.list && rm ~/.config/mimeapps.list && make restow PKG=mimeapps
```

Some entries point at apps installed outside pacman (`ai.storyteller.pdfcraft.desktop` from `update-apps`).
Until those are installed, the system falls back to the next app that handles the type.
Terminal apps (`nvim.desktop`, `micro.desktop`) open in kitty via `kitty/.config/xdg-terminals.list`.
