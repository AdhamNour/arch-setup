# Arch + Hyprland rice: Tokyo Night × Steins;Gate

A step-by-step recipe to rebuild this desktop from a fresh Arch install. It covers the whole path from power-on to desktop:

**GRUB theme → Plymouth divergence-meter splash → SDDM login → Hyprland** (waybar pills, blur, swaync, lock screen, themed GTK/Qt apps, terminal tooling).

Every config file and script referenced here is snapshotted under [`files/`](files/), mirroring its path in `$HOME`. For example, `files/.config/hypr/hyprland.lua` goes to `~/.config/hypr/hyprland.lua`.

## The machine this was built on

| | |
|---|---|
| Laptop | Acer Aspire A515-45G, Ryzen 7 5700U (Renoir iGPU) + Radeon 550X (Polaris dGPU), InsydeH2O BIOS |
| Panel | eDP-1, 1920×1080 (LG Display) |
| External | ARZOPA portable 1920×1080 on HDMI-A-1 (optional) |
| Disk | NVMe, btrfs subvolumes `@ @home @snapshots @var_log`, ESP mounted at `/boot` (vfat) |
| Boot | GRUB (UEFI), Secure Boot **off** (re-enable plan in [10](10-extras-and-troubleshooting.md)) |
| Versions | Hyprland **0.56.2**, which uses a **Lua** config (`~/.config/hypr/hyprland.lua`), not hyprlang `.conf` |

## Recipe order

| # | Chapter | Result |
|---|---|---|
| 01 | [Base system & Hyprland](01-base-system-and-hyprland.md) | Working session, look & feel, animations, autostart |
| 02 | [Wallpaper](02-wallpaper.md) | Generated nixie divergence-meter wallpaper on every screen |
| 03 | [Bar, launcher, notifications, power menu](03-bar-launcher-notifications-power.md) | Pill waybar, wofi, swaync control centre, wlogout |
| 04 | [App theming: GTK, Qt, icons, cursor, fonts, Chrome](04-app-theming.md) | Every app window in Tokyo Night, Arabic in Naskh |
| 05 | [Lock, idle, screenshots, clipboard, Bluetooth](05-lock-idle-utilities.md) | hyprlock, hypridle, screenshot script, cliphist, blueman |
| 06 | [Terminal](06-terminal.md) | kitty, Starship, fastfetch, eza/bat/btop/tmux |
| 07 | [Keyboard, monitors, window management](07-keyboard-monitors-windows.md) | EN/AR layouts, dual screen, Alt+Tab, minimize |
| 08 | [Login screen (SDDM)](08-login-sddm.md) | Custom QML greeter |
| 09 | [Boot: GRUB + Plymouth](09-boot-grub-plymouth.md) | Themed GRUB, animated splash |
| 10 | [Extras & troubleshooting](10-extras-and-troubleshooting.md) | Android emulator scaling, LaTeX, Secure Boot plan, gotchas |
| — | [Keybind cheat sheet](keybinds.md) | Every shortcut in one table |

## Palette (used everywhere)

| Name | Hex | Used for |
|---|---|---|
| bg_dark | `#16161e` | Deepest background, inputs, tab strip |
| bg | `#1a1b26` | Main background |
| bg_hl | `#292e42` | Highlights, inactive borders, buttons |
| fg | `#c0caf5` | Text |
| comment | `#565f89` | Dim text, captions |
| blue | `#7aa2f7` | Accent, active border start, focus |
| magenta | `#bb9af7` | Active border end, clock pill |
| cyan | `#7dcfff` | Secondary accent |
| orange | `#ff9e64` | Nixie tubes, warnings, critical notifications |
| red | `#f7768e` | Errors, power button |

Fonts: **JetBrainsMono Nerd Font** (UI and terminal), **Noto Sans** (app interfaces), **Noto Naskh Arabic** (Arabic).

## Golden rules learned the hard way

1. **Verify every install** with `pacman -Q <pkg>`. One install silently didn't happen.
2. **Hyprland 0.56 is Lua.** Check the API against `/usr/share/hypr/stubs/hl.meta.lua` and the example `/usr/share/hypr/hyprland.lua`. `hyprctl keyword` doesn't work, so use `hyprctl eval '<lua>'`. After every change, run `hyprctl reload && hyprctl configerrors`.
3. **Nerd Font glyphs (Private Use Area) get stripped** by some editors and tools. Write them by codepoint, e.g. Python `chr(0xf111)`, and check with `grep … | cat -A`.
4. **Back up before editing:** `cp file file.bak-$(date +%Y%m%d-%H%M)`.
5. **Take a btrfs snapshot before boot changes:** `sudo btrfs subvolume snapshot -r / /.snapshots/<name>`. The ESP (`/boot`) is **not** in btrfs snapshots, so copy it separately.
