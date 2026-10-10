# 01 · Base system & Hyprland

## Packages in this chapter

| Package | Role |
|---|---|
| `hyprland` | The Wayland compositor: windows, workspaces, animations, blur, keybinds. Configured in Lua in 0.56 |
| `xdg-desktop-portal-hyprland` | Lets apps share the screen, take screenshots and use global shortcuts under Hyprland (e.g. screen sharing in Chrome) |
| `xdg-desktop-portal-gtk` | Provides the file-open/save dialogs and settings portal for apps that ask through portals |
| `polkit-kde-agent` | Shows the graphical password prompt when an app needs admin rights (e.g. `pkexec`) |
| `pipewire` | The audio/video server |
| `pipewire-pulse` | Makes PipeWire look like PulseAudio, so apps like Chrome and pavucontrol work |
| `pipewire-alsa` | Routes old ALSA-only apps through PipeWire |
| `wireplumber` | PipeWire's session manager: picks default speakers/mic, handles plugging in headphones. Provides `wpctl` (volume keys) |
| `brightnessctl` | Changes screen brightness (brightness keys, waybar pill, hypridle dimming) |
| `playerctl` | Controls media players (play/pause/next keys) |
| `network-manager-applet` | `nm-applet` tray icon and `nm-connection-editor` for NetworkManager connections (the wifi pill opens `nmtui`, which comes with `networkmanager` itself) |
| `pavucontrol` | Volume mixer window (opened from the volume pill) |
| `thunar` | Graphical file manager (SUPER+E) |
| `ttf-jetbrains-mono-nerd` | Main UI/terminal font, with Nerd Font icons for waybar, Starship and fastfetch |
| `noto-fonts`, `noto-fonts-emoji` | Fallback fonts for all scripts (incl. Arabic Naskh/Kufi) and colour emoji |
| `openssh` | SSH client/server (enabled on this machine) |
| `base-devel`, `git` | Compiler tools and git, needed to build AUR packages |
| `yay` (AUR) | AUR helper: installs AUR packages like `pacman` does |

## 1. Packages

Base session (what the rice started from):
```bash
sudo pacman -S hyprland waybar kitty wofi xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  polkit-kde-agent pipewire pipewire-pulse pipewire-alsa wireplumber hyprpaper brightnessctl \
  network-manager-applet pavucontrol thunar playerctl grim slurp \
  ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji openssh
```

AUR helper (`yay`):
```bash
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
```

Everything else the rice uses (later chapters explain each one):
```bash
sudo pacman -S papirus-icon-theme qt6ct kvantum nwg-look hyprlock hypridle swaync cliphist \
  wl-clipboard fastfetch eza bat btop tmux starship sddm plymouth bluez bluez-utils blueman
yay -S tokyonight-gtk-theme-git bibata-cursor-theme-bin papirus-folders wlogout
```

**Check every package actually installed:** `pacman -Q <name>`.

## 2. Hyprland config (Lua)

Copy [`files/.config/hypr/hyprland.lua`](files/.config/hypr/hyprland.lua) to `~/.config/hypr/hyprland.lua`. Its sections, top to bottom:

| Section | What it does |
|---|---|
| PATH guard | Adds `~/.local/bin` to PATH, because SDDM doesn't run `~/.bash_profile` (see 08) |
| `hl.env` | Bibata cursor (`XCURSOR_*`, `HYPRCURSOR_*`), and Qt → `qt6ct` with Wayland first |
| `hl.monitor` | Catch-all rule plus the dual-screen logic (see 07) |
| `tn` palette | Tokyo Night colours used by the borders |
| `hl.config` | gaps 8/16, border 2 (blue→magenta gradient 45°), rounding 12, inactive opacity 0.92, shadow, blur (size 8, passes 3, vibrancy 0.18), dwindle `preserve_split`, input (`us,ara`), `xwayland.force_zero_scaling`, no default wallpaper or logo |
| Animations | Springs `snappy` and `bouncy`; windows pop in (`popin 85%`), workspaces `slidefade 15%`, layers slide. **No `borderangle` loop**, because it redraws every frame and drains the battery |
| `hl.layer_rule` | Blur behind waybar, wofi, swaync and wlogout; no animation on the slurp selection |
| `hl.gesture` | 3-finger horizontal swipe switches workspace |
| `hl.on("hyprland.start")` | Autostart: waybar, hyprpaper, swaync, hypridle, blueman-applet, cliphist watchers, polkit agent |
| Binds | See [keybinds.md](keybinds.md) |
| Window rules | Float the Android emulator, blueman and btop |

## 3. Lua API notes (0.56)

- **Dispatchers:** `hl.dsp.exec_cmd`, `hl.dsp.window.{close,float,fullscreen,move,pseudo,drag,resize,cycle_next}`, `hl.dsp.focus`, `hl.dsp.workspace.toggle_special`, `hl.dsp.layout`.
- **Arguments that had to be found by testing:**
  - `fullscreen({ mode = "fullscreen" | "maximized" })`
  - `move({ workspace = …, follow = false })` (`silent = true` is ignored)
  - `cycle_next({ next = false })` goes backwards
- **Find valid argument values by probing:** `hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "x" })'` errors with the list of valid values.
- **`hl.bind(keys, dispatcher_or_function, { repeating, locked, mouse })`**: binds accept Lua functions too.
- **Window rule sizes** take expressions (`"monitor_w*0.85 monitor_h*0.85"`), not `"85%"`.

## 4. Verify

```bash
hyprctl reload && hyprctl configerrors     # must print nothing
hyprctl binds | grep -c '^bind'            # sanity count
```
