# Omarchy overrides

GNU Stow package for personal Omarchy Quattro input and keybinding overrides.
It intentionally contains only files loaded after Omarchy's packaged defaults.
The older `hypr/` package is a standalone Hyprland setup and must not be stowed on an Omarchy installation.

Install the user configuration with:

```sh
make stow-omarchy
```

The Caps Lock tap-Escape/hold-Control mapping is system-level and is tracked separately in [`keyd/default.conf`](../keyd/default.conf).
Install it on Arch Linux with:

```sh
sudo pacman -S --needed keyd
sudo install -Dm644 keyd/default.conf /etc/keyd/default.conf
sudo systemctl enable --now keyd.service
```

After changing `keyd/default.conf`, run `sudo keyd reload` or restart `keyd.service`.
