# 03 · Bar, launcher, notifications, power menu

## 1. Waybar: floating pills

Copy [`files/.config/waybar/`](files/.config/waybar/) (`config.jsonc`, `style.css`, `scripts/kb-layout.py`).

- **Layout:** each module is its own rounded pill (`border-radius: 17px`) on a translucent `rgba(26,27,38,0.72)` background, with margins 10 px top and 16 px sides. Blur comes from the Hyprland layer rule (01).
- **Left:** Arch launcher (opens wofi), workspace dots, window title.
- **Centre:** clock. Click it for the full date, hover for a calendar.
- **Right:** tray, CPU, memory, brightness (scroll to adjust), **keyboard layout** (07), volume (click for pavucontrol, right-click to mute), Bluetooth (click for blueman, right-click to toggle), wifi (click for `nmtui`), battery, **notification bell** (swaync), **power** (wlogout).
- **Icons** are Nerd Font codepoints. They were written with Python `chr()` because typing them directly into a file stripped them (blank pills).
- **The keyboard layout pill is a custom module** (`scripts/kb-layout.py`): waybar 0.15's built-in `hyprland/language` only shows "…" with Hyprland 0.56. The script reads `activelayout>>` events from Hyprland's `.socket2.sock`.

```bash
pkill -x waybar; hyprctl dispatch 'hl.dsp.exec_cmd("waybar")'
```

## 2. Wofi: launcher

Copy [`files/.config/wofi/`](files/.config/wofi/). It's a centred 560×380 box with a translucent `#1a1b26` background, a 2 px blue border, rounded corners, and Papirus icons. Open it with **SUPER+R** or the Arch pill.

## 3. Swaync: notifications and control centre (replaces dunst)

Copy [`files/.config/swaync/`](files/.config/swaync/) (`config.json`, `style.css`, `scripts/wifi.sh`, `scripts/bluetooth.sh`).

- **`style.css`** is swaync's default stylesheet with its colour variables swapped to Tokyo Night, plus additions at the end.
- **Widgets:** title, Do Not Disturb, a button grid (wifi toggle, Bluetooth toggle, screenshot, lock, power), mpris, volume, backlight, notification list.
- **Pop-up spacing** is done in CSS (`.floating-notifications { margin: 10px 16px 0 0 }`), because swaync has no config option for it.
- **Gotchas found while testing:**
  - Active toggles get the **`.active`** CSS class (see `man 5 swaync`), not `:checked`.
  - The toggle state commands **must be scripts** (`scripts/*.sh status|toggle`). Inline `sh -c '…'` commands with nested quotes returned false when run by swaync.
- **Waybar bell:** `swaync-client -swb`. Click to toggle the panel, right-click for Do Not Disturb.

```bash
swaync-client -R && swaync-client -rs      # reload config + CSS
notify-send "Test" "Hello"; swaync-client -op
```

## 4. Wlogout: power menu

Copy [`files/.config/wlogout/`](files/.config/wlogout/) (`layout`, `style.css`, `icons/`).

- **Buttons:** Lock / Logout / Suspend / Reboot / Shutdown, with keyboard letters l / e / u / r / s.
- **The stock icons are black SVGs** with no fill, which disappear on a dark background. The copies in `icons/` add `fill="<colour>"` to the `<svg>` tag, one Tokyo Night colour per button.
- **`style.css` uses absolute icon paths** (`/home/adham/.config/wlogout/icons/…`). Change these if your username differs.
- **Logout** runs `hyprctl dispatch 'hl.dsp.exit()'`.
- **Open it with** SUPER+Escape, SUPER+M or the ⏻ pill (`wlogout -b 5 -p layer-shell`).
