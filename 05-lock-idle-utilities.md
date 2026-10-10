# 05 · Lock, idle, screenshots, clipboard, Bluetooth

## Packages in this chapter

| Package | Role |
|---|---|
| `hyprlock` | The lock screen (SUPER+L, before suspend, after idle) |
| `hypridle` | Watches for inactivity: dims, locks, turns the screen off, suspends on battery |
| `grim` | Takes screenshots on Wayland |
| `slurp` | Lets you drag-select an area for the screenshot |
| `wl-clipboard` | `wl-copy`/`wl-paste`: Wayland clipboard on the command line (screenshots to clipboard, cliphist) |
| `cliphist` | Stores clipboard history (SUPER+V) |
| `bluez` | The Bluetooth stack/daemon (`bluetooth.service`) |
| `bluez-utils` | `bluetoothctl`, used by the swaync toggle and the pill's right-click |
| `blueman` | Bluetooth GUI (`blueman-manager`) and pairing agent (`blueman-applet`) |

## 1. hyprlock: lock screen

hyprlock and hypridle still use **hyprlang** `.conf` syntax, not Lua. Reference copies ship at `/usr/share/hypr/hyprlock.conf` and `/usr/share/hypr/hypridle.conf`.

Copy [`files/.config/hypr/hyprlock.conf`](files/.config/hypr/hyprlock.conf). It shows:
- the divergence wallpaper, blurred (3 passes, brightness 0.55)
- a big **nixie-orange clock** in Noto Sans Light with an orange glow shadow
- the date, and the user with an icon
- a password field (blue→magenta border, placeholder *El Psy Kongroo…*)
- a "WORLDLINE DIVERGENCE · 1.048596" footer
- a **clickable keyboard layout label** (`$LAYOUT[EN,ع]`), because your password is typed in whatever layout is active

Lock with **SUPER+L** (`loginctl lock-session`).

Safe test: `hyprlock --grace 30`. Any key or mouse movement unlocks during the first 30 s.

## 2. hypridle: idle timeouts

Copy [`files/.config/hypr/hypridle.conf`](files/.config/hypr/hypridle.conf):

| After | Action |
|---|---|
| 4 min | Dim to 10% (`brightnessctl -s`, restored on resume) |
| 5 min | Lock |
| 6 min | Screen off (`hyprctl dispatch 'hl.dsp.dpms({action = "off"})'`) |
| 15 min | Suspend, **only on battery** (checks `/sys/class/power_supply/ACAD/online`) |

It also locks before any suspend. There's no keyboard backlight on this laptop, so that part of the stock config is removed.

## 3. Screenshots

Copy [`files/.local/bin/screenshot`](files/.local/bin/screenshot) and run `chmod +x ~/.local/bin/screenshot`. **Don't forget the chmod**: the first test failed without it.

- **Modes:** `full`, `area` (slurp, with a Tokyo Night selection colour), `window` (the active window's geometry from `hyprctl -j activewindow`).
- **Each screenshot** is saved to `~/Pictures/Screenshots`, copied to the clipboard, and announced in a notification with Open / Show in folder actions.
- **Keys:** Print, SHIFT+Print, SUPER+SHIFT+Print, SUPER+SHIFT+P.

## 4. Clipboard history

Autostarted in `hyprland.lua`: `wl-paste --type text|image --watch cliphist store`.

**SUPER+V** opens the history picker (`cliphist list | wofi --dmenu | cliphist decode | wl-copy`). Toggle floating moved from SUPER+V to **SUPER+SHIFT+F**.

## 5. Bluetooth

```bash
sudo pacman -S bluez bluez-utils blueman && sudo systemctl enable --now bluetooth
gsettings set org.blueman.general plugin-list "['!StatusNotifierItem']"   # no duplicate tray icon
```
- **blueman-applet** is autostarted, because it handles pairing PIN prompts.
- **blueman-manager** opens from the waybar pill as a 560×440 floating window.
- The **swaync Bluetooth toggle** uses `~/.config/swaync/scripts/bluetooth.sh`.
