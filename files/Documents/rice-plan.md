# Finish the Tokyo Night × Steins;Gate Hyprland rice

## Context
The core session is stable and themed: Hyprland 0.56.2 Lua config, pill waybar, wofi, dunst, kitty, Starship prompt, generated divergence-meter wallpaper, emulator scaling fixed. What's left: app windows (GTK/Qt) are stock Adwaita, some desktop features are missing (lock, idle, screenshots, clipboard, power menu, notification centre), animations are defaults, and boot and login are stock (text console login, starfield GRUB, no splash).

The goal is a cohesive rice from power-on to desktop. Decisions made:
- **Login:** SDDM (graphical).
- **Notifications:** switch from dunst to swaync.
- **Keys:** SUPER+V = clipboard, SUPER+SHIFT+F = float, SUPER+F = fullscreen.
- **Scope:** all four areas.

## Ground rules (every phase)
- Back up each file before editing it (`*.bak-YYYYmmdd-HHMM`, as done so far). Verify each Hyprland change with `hyprctl reload` + `hyprctl configerrors`, and verify visually with `grim` screenshots.
- Check Lua API against `/usr/share/hypr/stubs/hl.meta.lua` and `/usr/share/hypr/hyprland.lua`, never from memory (hyprlang syntax does not apply).
- Colours: reuse the `tn` palette table at the top of `~/.config/hypr/hyprland.lua`, and the same hex values as `~/.config/waybar/style.css`.
- sudo needs the user's password, so group installs into a few `! sudo pacman -S …` / `! yay -S …` commands for the user to run. Confirm with `pacman -Q` afterwards (the first starship install silently didn't happen).
- Before Phase 5 (boot), take a btrfs snapshot of `@`. Check where `@snapshots` is mounted first.

## Installs (user runs these at the start)
```
sudo pacman -S papirus-icon-theme qt6ct kvantum nwg-look hyprlock hypridle swaync cliphist wl-clipboard fastfetch eza bat btop sddm plymouth
yay -S tokyonight-gtk-theme-git bibata-cursor-theme-bin papirus-folders wlogout
```
Confirm the AUR package names with `yay -Ss` before handing over the command.

## Phase 1: App look (GTK, Qt, icons, cursor)
- **GTK:** Tokyo Night GTK theme (dark, blue accent) + Papirus-Dark (`papirus-folders -C indigo` or closest to #7aa2f7) + Bibata-Modern-Ice cursor.
  - Write `~/.config/gtk-3.0/settings.ini` and `gtk-4.0` (+ libadwaita `gtk.css` link), and set `gsettings` (color-scheme prefer-dark, gtk-theme, icon-theme, cursor-theme, font "Noto Sans 10").
- **Cursor:** in `hyprland.lua`, `hl.env` `XCURSOR_THEME`/`HYPRCURSOR_THEME` = Bibata, size 24.
- **Qt:** `hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")`, a Kvantum Tokyo Night theme, qt6ct set to Kvantum + Papirus. Do **not** set `QT_SCALE_FACTOR` globally (it would double-scale the Wayland Qt apps).
- **wofi:** enable icons from Papirus (config already has `allow_images`).
- **Verify:** screenshot Thunar, pavucontrol, the polkit prompt (`pkexec true`), and a GTK file dialog.

## Phase 2: Missing functionality
- **swaync** replaces dunst.
  - Autostart swap in `hl.on("hyprland.start")`.
  - Write `~/.config/swaync/config.json` + `style.css` (port colours from `~/.config/dunst/dunstrc`) with widgets: title, DND, notifications, volume, backlight, buttons (wifi, bluetooth-if-present).
  - Add a bell pill `custom/notification` to waybar (`swaync-client -swb`), and the layer_rule blur for namespaces `swaync-control-center` and `swaync-notification-window` (same pattern as the existing blur rules).
  - Remove dunst from autostart. Leave the package installed.
- **hyprlock + hypridle.**
  - `~/.config/hypr/hyprlock.conf`: blurred divergence wallpaper, big clock, date, "El Psy Kongroo" label, Tokyo Night input field.
  - `~/.config/hypr/hypridle.conf`: dim at 4 min, lock at 5, screen off at 6, suspend at 15 on battery, plus `before_sleep_cmd` lock.
  - Check the config syntax against the installed version's docs or man pages; these may be hyprlang, not Lua.
  - Keys: SUPER+L = lock.
- **Screenshots** (grim/slurp/wl-copy, installed):
  - `~/.local/bin/screenshot` script: modes full / area / window, saves to `~/Pictures/Screenshots`, copies to clipboard, sends a notification with the image as its icon.
  - Keys: Print, SHIFT+Print, SUPER+SHIFT+Print.
- **Clipboard:** autostart `wl-paste --watch cliphist store`. SUPER+V = `cliphist list | wofi --dmenu | cliphist decode | wl-copy`.
- **Power menu:** wlogout with a Tokyo Night `style.css` + blur layer rule.
  - Waybar ⏻ pill and SUPER+Escape open it.
  - Retire `~/.config/waybar/scripts/power.sh`.
- **Keybind changes:** SUPER+F fullscreen, SUPER+SHIFT+F float (moved from SUPER+V).
  - Also pass the old SUPER+M exit through wlogout, or keep it but show a confirmation first.
- **Verify:** trigger each bind, screenshot the lock screen (with a grace period to unlock) and the control centre, run `notify-send` tests, check `hyprctl binds` count.

## Phase 3: Animations + terminal
- **Animations:** add curves and `hl.animation` leaves (syntax from `/usr/share/hypr/hyprland.lua` lines 136–161).
  - Spring pop-in for windows, `slidefade` workspaces, smooth layers for wofi/swaync.
  - Keep it snappy (no animation over ~400 ms).
- **fastfetch:** `~/.config/fastfetch/config.jsonc` with a Steins;Gate ASCII logo (divergence number or gear motif) in Tokyo Night colours. Run it from `~/.bashrc` for interactive shells only.
- **CLI tools:**
  - `eza` aliases (`ls`/`ll`/`tree` with icons, replacing the current `ls` alias).
  - `bat` with the built-in `TwoDark`, or Tokyo Night tmTheme + `bat cache --build`.
  - `btop` Tokyo Night theme.
  - tmux (already installed) Tokyo Night status line.
- **Verify:** open a new kitty and screenshot it, record animations visually, confirm no bashrc startup errors (`bash -ic exit`).

## Phase 4: Login screen (SDDM)
- Enable `sddm.service` (the user runs it).
- Theme: a small custom QML theme in `/usr/share/sddm/themes/steins-gate/`, or sddm-astronaut configured with our wallpaper.
  - It should show the divergence wallpaper, a clock, a Tokyo Night password field, and a session picker defaulting to Hyprland.
  - Preview with `sddm-greeter-qt6 --test-mode --theme …` before enabling.
- Check that `/usr/share/wayland-sessions/hyprland.desktop` exists, and set Bibata as the SDDM cursor.

## Phase 5: GRUB + Plymouth (snapshot first)
- **GRUB:** custom theme in `/boot/grub/themes/tokyo-night/`.
  - Background rendered from `~/Pictures/wallpapers/src/divergence.py` at 1920×1080, with a variant that has the meter dimmed.
  - `theme.txt` with JetBrains Mono (converted via `grub-mkfont`) and Tokyo Night menu colours.
  - Set `GRUB_THEME` and `GRUB_GFXMODE=1920x1080` in `/etc/default/grub`, then `grub-mkconfig -o /boot/grub/grub.cfg`.
- **Plymouth:** custom script theme.
  - Divergence-meter boot animation: extend `divergence.py` to render frames of nixie digits cycling and then locking onto 1.048596.
  - Add the `plymouth` hook after `systemd` in `/etc/mkinitcpio.conf` HOOKS (current: `base systemd autodetect microcode modconf kms …`), add `splash` to `GRUB_CMDLINE_LINUX_DEFAULT`, `plymouth-set-default-theme`, `mkinitcpio -P`.
  - `kms` is already present, so amdgpu gets early KMS.
- **Verify:** `plymouthd; plymouth --show-splash` preview before rebooting, then reboot and watch GRUB → splash → SDDM → Hyprland.
  - Rollback: restore `/etc/default/grub` and `mkinitcpio.conf` backups, or boot the btrfs snapshot.

## Critical files
- `~/.config/hypr/hyprland.lua` (env, autostart, binds, layer rules, animations)
- New files: `~/.config/hypr/hyprlock.conf`, `~/.config/hypr/hypridle.conf`, `~/.config/swaync/*`, `~/.config/wlogout/*`, `~/.config/fastfetch/config.jsonc`, `~/.config/gtk-{3,4}.0/*`, `~/.config/qt6ct/*`, `~/.config/Kvantum/*`
- `~/.config/waybar/config.jsonc` + `style.css` (notification pill, power pill → wlogout)
- `~/.bashrc` (fastfetch, eza aliases)
- `~/Pictures/wallpapers/src/divergence.py` (reused for lock, SDDM, GRUB and Plymouth art)
- System: `/etc/default/grub`, `/etc/mkinitcpio.conf`, `/usr/share/sddm/themes/`, `/boot/grub/themes/`, `/usr/share/plymouth/themes/`

## End-to-end check
Full reboot. GRUB shows the Tokyo Night theme, the Plymouth divergence animation plays, the SDDM login appears, Hyprland starts with waybar/swaync/hypridle/cliphist running (`pgrep`), and `hyprctl configerrors` is empty. Then open Thunar, pavucontrol and wofi and screenshot them, and test each new keybind: SUPER+L, Print, SUPER+V, SUPER+Escape, SUPER+F.

## Progress
- **Phase 1: done (2026-09-25).**
  - GTK: Tokyonight-Dark, with the libadwaita css linked in ~/.config/gtk-4.0 and a Thunar sidebar fix in ~/.config/gtk-3.0/gtk.css.
  - Icons and cursor: Papirus-Dark + Bibata-Modern-Ice (env in hyprland.lua + gsettings + ~/.icons/default).
  - Qt: qt6ct → Kvantum "TokyoNight" (~/.config/Kvantum/TokyoNight, recoloured from KvArcDark).
  - Papirus folders set to indigo.
- **Phase 2: done (2026-09-25).**
  - swaync replaces dunst: ~/.config/swaync, bell pill in waybar, SUPER+N.
  - hyprlock/hypridle: ~/.config/hypr/hyprlock.conf + hypridle.conf, SUPER+L. Idle: dim at 4 min, lock at 5, screen off at 6, suspend at 15 on battery only.
  - Screenshots: ~/.local/bin/screenshot. Print = full, SHIFT+Print = area, SUPER+SHIFT+Print = window, SUPER+SHIFT+P = area.
  - Clipboard: cliphist on SUPER+V.
  - wlogout: SUPER+Escape / SUPER+M / ⏻ pill.
  - Keys: SUPER+F fullscreen, SUPER+CTRL+F maximise, SUPER+SHIFT+F float.
  - Bluetooth (added later): toggle in the control centre (via ~/.config/swaync/scripts/*.sh) + waybar pill (click = blueman-manager, right-click = power toggle). blueman-applet autostarts for pairing prompts; its tray icon is disabled via gsettings plugin-list ['!StatusNotifierItem'].
- **Phase 3: done (2026-09-25).**
  - Animations: spring pop-in windows, slidefade workspaces, sliding layers (no always-on borderangle loop, to save battery).
  - fastfetch: ASCII nixie divergence meter logo (~/.config/fastfetch/divergence.txt), shown once per kitty window.
  - eza aliases (ls/ll/la/lt), bat (official tokyonight_night theme, also used as `cat` and as the man pager).
  - btop: tokyo-night theme, floating 85% window on SUPER+SHIFT+Escape.
  - tmux: ~/.tmux.conf with prefix Ctrl+a, `|`/`-` splits, Tokyo Night status bar at the top.
- **Phase 4: done (2026-09-25).** Installed to /usr/share/sddm/themes/steins-gate + /etc/sddm.conf.d/10-steins-gate.conf, sddm enabled, verified after reboot.
  - SDDM theme source is ~/.local/share/sddm-themes/steins-gate (Main.qml, Qt6, blurred divergence background, glowing nixie clock). Config: ~/.local/share/sddm-themes/10-steins-gate.conf.
  - hyprland.lua now adds ~/.local/bin to PATH itself (SDDM skips ~/.bash_profile).
  - Rollback: Ctrl+Alt+F2 → log in → `sudo systemctl disable sddm` → reboot.
- **Phase 5: installed (2026-09-25); review fixes in 3-update.sh, then reboot.**
  - Source: ~/.local/share/boot-theme/ (grub/steins-gate, plymouth/steins-gate + render_assets.py, staged etc/ files).
  - Run: `sudo bash ~/.local/share/boot-theme/1-backup.sh` then `sudo bash ~/.local/share/boot-theme/2-install.sh`.
  - divergence.py gained --no-caption / --y-shift=PX flags (default output unchanged).
  - Review (2026-09-25): GRUB theme verified against gfxmenu.mod property names, grub-script-check, PNG/font formats. Plymouth script rewritten to example-proven syntax; early splash via plymouth.use-simpledrm; DeviceTimeout=15.
  - Observation: amdgpu takes ~4.5 s to load in the initramfs (hybrid Polaris dGPU + Renoir iGPU; TSC marked unstable → HPET). Not theme-related; worth a look someday.
