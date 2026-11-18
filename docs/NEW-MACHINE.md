# New machine setup

These dotfiles target Arch-based systems (Arch, CachyOS, EndeavourOS, Omarchy).
`bootstrap.sh` refuses to run anywhere else, because `deps.conf` uses Arch package names.

## TL;DR

```sh
sudo pacman -S --needed git stow make
git clone <this repo> ~/dev/github.com/mshiyaf/dotfiles
cd ~/dev/github.com/mshiyaf/dotfiles
./bootstrap.sh --dry-run   # see every step, change nothing
make bootstrap             # guided setup, asks before each change
make check                 # any time later: what is linked, what is missing
```

Clone to exactly `~/dev/github.com/mshiyaf/dotfiles`.
`tmux.conf` and some zsh aliases hardcode that path; bootstrap warns if the repo is elsewhere.

## How the pieces fit

| File | Role |
|---|---|
| `Makefile` | Runs GNU Stow. `make stow` links `DEFAULT_PACKAGES` into `$HOME`; `make stow-<pkg>` links one package. |
| `deps.conf` | Which apps each package needs, where they come from, and whether they are required or optional. |
| `bootstrap.sh` | Guided setup built on the two files above. `make bootstrap` and `make check` call it. |

Each top-level directory is a stow package that mirrors `$HOME`.
For example `kitty/.config/kitty/kitty.conf` becomes the link `~/.config/kitty/kitty.conf`.

Stow runs with `--no-folding`, so it creates real directories and links individual files.
`voxtype` is the exception (`FOLDED_PACKAGES` in the Makefile): `~/.config/voxtype` is one directory link, because Voxtype saves its config by renaming a temp file, which would replace a file link.
Its systemd drop-in directory stays a real directory, because systemd ignores symlinked drop-in directories.

Stow never overwrites an existing file.
On a fresh machine that already has, say, a default `~/.zshrc`, plain `make stow` aborts with a conflict.
Bootstrap handles that by backing the file up first.

## What `make bootstrap` does

1. **System check.** Stops unless `/etc/os-release` says Arch or Arch-like and `pacman` exists, and refuses to run as root.
   Offers to install `git`, `stow` and `make` if they are missing.
2. **Desktop detection.** Reads the running session and the installed window managers, then suggests a profile you can change:

   | Profile | Desktop packages added |
   |---|---|
   | `niri` | niri, noctalia, voxtype |
   | `hyprland` | hypr, waybar, swaync, rofi, wlogout, wallust, swappy, Kvantum, qt5ct, qt6ct |
   | `omarchy` | omarchy (overrides only; never `hypr` on top of Omarchy) |
   | `i3` | i3, i3status, picom, rofi |
   | `none` | nothing (GNOME, KDE, servers) |

   Every profile also gets the desktop-independent packages from `DEFAULT_PACKAGES`: shell, editor, git, terminals, agent tools and scripts.
   Add more with `--add "lazygit btop"`.
3. **Backup.** Every existing file or link that a package would replace is copied to `~/.local/state/dotfiles-backup/<timestamp>/` with a `MANIFEST`, then archived as `<timestamp>.tar.gz`.
   The archive is verified before anything else happens, and nothing is removed in this step.
4. **App check and install.** Lists missing apps per package, marked required or optional.
   - Official repo packages: one confirmation, then `sudo pacman -S --needed`.
   - AUR packages that a configured repo (CachyOS, chaotic-aur) ships are installed with pacman.
     The rest are listed with their AUR links and installed with `paru` or `yay` only after a separate confirmation.
   - Vendor-installed tools (Claude Code, Amp, OpenCode, herdr, ...) are printed for you to run; bootstrap never pipes an installer into a shell.
5. **Stow.** Runs `agents-sync` (only for a real install into `$HOME`), shows the paths that will be replaced, asks, removes them and runs `make stow` for the chosen packages.
6. **System files.** Offers the keyd Caps Lock mapping, the USB notify udev rule, and TCP BBR (all need sudo), skipping ones already installed.
7. **Next steps.** Prints what is left (see below).

## Flags

```sh
./bootstrap.sh --check              # read-only report; exit 1 if anything is missing
./bootstrap.sh --dry-run            # print every action instead of doing it
./bootstrap.sh --profile hyprland   # skip detection
./bootstrap.sh --add "lazygit btop" # stow extra packages
TARGET=/tmp/test ./bootstrap.sh     # link into another directory (testing)
```

## Still manual

- **Login shell:** `chsh -s "$(command -v zsh)"`.
- **Dictation (niri profile):** `voxtype setup model` (pick small.en), `voxtype setup systemd`, `systemctl --user enable --now voxtype`.
  Run these after stowing, so Voxtype finds the tracked config.
  `gpu_device = 0` is the G14's integrated GPU; check the index on other hardware with `voxtype setup gpu`.
- **Apps outside pacman** (Hype, Disktree, AppImages, .deb apps): run `check-app-updates`, then `update-apps`.
- **Pin Hype and Disktree:** add `IgnorePkg = hype disktree-bin` to `/etc/pacman.conf`.
- **Mic level:** the 28% input volume is tuned for the G14 and stored by PipeWire, not in the repo.
- **SDDM HiDPI:** `sddm/etc/sddm.conf.d/hidpi.conf` is tuned to one 2560x1600 panel.
  Copy it to `/etc/sddm.conf.d/` by hand if it fits.
- **CUPS label printer:** see `cups/README.md`.

## Keeping it current

When a package gains a new dependency, add a line to `deps.conf`.
When you add a desktop-specific package, add it to `PROFILE_PKGS` in `bootstrap.sh`.
When a package needs folding, add it to `FOLDED_PACKAGES` in both the Makefile and `bootstrap.sh`.
