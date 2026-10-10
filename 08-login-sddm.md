# 08 · Login screen (SDDM)

A custom Qt 6 QML greeter called `steins-gate`:
- the divergence wallpaper, blurred and dimmed
- a large nixie-orange clock with a glow (`MultiEffect`), and the date
- the user name and an "El Psy Kongroo…" password field
- a session picker (bottom-left) and power buttons (bottom-right)
- a footer reading "WORLDLINE DIVERGENCE · 1.048596"

## 1. Prerequisites

- `sddm` installed. **`xorg-server` must be installed too**, because the SDDM greeter runs on X11 by default.
- Check that `/usr/share/wayland-sessions/hyprland.desktop` exists (Exec=`/usr/bin/start-hyprland`). There's also `hyprland-uwsm.desktop`, but **uwsm isn't installed**, so the theme defaults to plain "Hyprland".

## 2. Build and preview (no root needed)

```bash
T=~/.local/share/sddm-themes/steins-gate; mkdir -p $T
cp files/.local/share/sddm-themes/steins-gate/* $T/
cp ~/Pictures/wallpapers/steins-gate-divergence.png $T/background.png
sddm-greeter-qt6 --test-mode --theme $T       # preview; close the window when done
```
- **Sizing:** everything is relative to the screen height (`s = height / 1080`).
- **Placeholder:** the password field draws **its own** placeholder text, because Qt's Basic style hides the placeholder on a focused, centred field.
- **First boot:** if SDDM has no remembered user, the theme picks the first account, so you see "adham" instead of an empty username box.
- **Power buttons** are hidden in test mode. They appear on the real login screen.

## 3. Install and enable (sudo)

```bash
sudo cp -r ~/.local/share/sddm-themes/steins-gate /usr/share/sddm/themes/
sudo install -Dm644 files/.local/share/sddm-themes/10-steins-gate.conf /etc/sddm.conf.d/10-steins-gate.conf
sudo systemctl enable sddm        # takes effect on next boot
```
`10-steins-gate.conf` sets `DisplayServer=x11`, `Current=steins-gate` and the Bibata cursor.

## 4. PATH under SDDM

SDDM doesn't run `~/.bash_profile`, so `~/.local/bin` (`screenshot`, `minimized`, `emulator`) would drop out of PATH. That's why `hyprland.lua` starts with a Lua block that adds it with `hl.env("PATH", …)`.

To verify after login, check a child process, not Hyprland itself:
```bash
tr '\0' '\n' < /proc/$(pgrep -x waybar)/environ | grep ^PATH=
```

## Rollback

Press Ctrl+Alt+F2, log in on the text console, run `sudo systemctl disable sddm`, then reboot.
