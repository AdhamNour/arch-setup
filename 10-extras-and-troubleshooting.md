# 10 · Extras & troubleshooting

## Packages in this chapter

| Package | Role |
|---|---|
| `android-studio` (AUR) | Android IDE. Its SDK emulator is what needed the XWayland scaling fix |
| `texlive-basic`, `texlive-latex`, `texlive-latexrecommended` | Core TeX engine, `pdflatex` and standard LaTeX packages |
| `texlive-latexextra` | The large collection of extra LaTeX packages most documents use |
| `texlive-fontsrecommended` | Standard fonts for LaTeX |
| `texlive-xetex`, `texlive-luatex` | `xelatex` / `lualatex`: Unicode engines that use system fonts (needed for Arabic) |
| `texlive-langarabic` | Arabic support: polyglossia/arabxetex, hyphenation |
| `texlive-binextra` | Extra tools, including `latexmk` (auto-rebuild) |
| `texlive-mathscience`, `texlive-pictures` | Maths/science packages and TikZ/diagrams |
| `texlive-bibtexextra`, `biber` | Bibliographies (biblatex backend) |
| `ttf-amiri` (optional) | Arabic font that includes the em dash, which Noto Naskh lacks |
| `sbctl` (planned) | Manages your own Secure Boot keys and signs GRUB and the kernel |

## Android emulator: sharp on a scaled screen

**Problem:** the emulator only ships an X11 backend (`~/Android/Sdk/emulator/lib64/qt/plugins/platforms/` has `xcb` but no `wayland`). Running through XWayland at 1.5× made icons and text soft and pixelated.

**Fixes:**
1. **Native resolution for XWayland:** `xwayland = { force_zero_scaling = true }` in `hyprland.lua`.
2. **Smaller AVD:** Pixel_6a was changed to **720×1600 @ 280 dpi**. It keeps the same 411×914 dp layout, so apps look the same, and the window shrinks it far less. The device frame is off, because the frame image is hardcoded for 1080×2400. Edit `~/.android/avd/Pixel_6a.avd/config.ini`, then **cold boot**.
3. **Floating window:** the window rule `class ^Emulator$` makes it float at its own size.
4. **Terminal launches:** [`files/.local/bin/emulator`](files/.local/bin/emulator) wraps the SDK emulator with `QT_SCALE_FACTOR`. Android Studio launches the SDK binary directly, so this only applies when you start it from a terminal.

## LaTeX (~680 MB)

```bash
sudo pacman -S texlive-basic texlive-latex texlive-latexrecommended texlive-latexextra \
  texlive-fontsrecommended texlive-xetex texlive-luatex texlive-langarabic texlive-binextra \
  texlive-mathscience texlive-pictures texlive-bibtexextra biber
```
- **English:** `latexmk -pdf file.tex`. **Arabic:** `latexmk -xelatex file.tex`, using polyglossia with `\newfontfamily\arabicfont[Script=Arabic]{Noto Naskh Arabic}`.
- **Noto Naskh has no em dash (—)**, so it renders as an empty box. Install `ttf-amiri` if you need it.
- Testing tip: never redirect compiler output to `<name>.out`. hyperref uses that file for its bookmarks.

## Secure Boot (planned, not done)

See [`files/Documents/secure-boot-plan.md`](files/Documents/secure-boot-plan.md). In short:
1. Set an Acer supervisor password and erase the Secure Boot keys (Setup Mode).
2. Run `sbctl create-keys` and `sbctl enroll-keys -m`. **Keep the Microsoft keys**, which firmware option ROMs need.
3. Reinstall GRUB with `--disable-shim-lock` and the needed modules built in, then sign GRUB and the kernel with `sbctl sign -s`.
4. Do a test boot with Secure Boot still off, then enable it.

## Gotchas collected along the way

| Symptom | Cause → fix |
|---|---|
| `unknown config key 'dwindle.pseudotile'` | Removed in 0.56. Pseudotile is now a dispatcher (`SUPER+P`) |
| Blank waybar or tmux icons | Nerd Font glyphs stripped while writing the file → write them with `chr(0x…)` |
| `hyprctl keyword …` refused | Lua config → use `hyprctl eval '<lua>'` |
| `pkill -f <pattern>` killed my own shell | It matches its own command line → use `pkill -x name` |
| Process names over 15 chars | `pkill -x` can't match them → close windows via `hyprctl clients` + `hl.dsp.window.close({ window = 'address:0x…' })` |
| `grim` wrong area | grim uses **logical** coordinates (physical ÷ scale) |
| `"85%"` window size ignored | Use expressions: `"monitor_w*0.85 monitor_h*0.85"` |
| swaync toggles never highlight | The class is `.active`, and the state commands must be scripts |
| Thunar sidebar selection unreadable | Tokyonight GTK bug → `~/.config/gtk-3.0/gtk.css` override |
| Arabic in Kufi on websites | `65-nonlatin.conf` → reject Noto Sans Arabic in user fontconfig (04) |
| Ctrl+C/V "don't work" in kitty | Terminal convention → `copy_or_interrupt` mapping (06) |
| Old Hyprland instance dirs in `/run/user/1000/hypr/` | Leftovers from earlier sessions, harmless |

## Not yet done / ideas

- Load the Chrome theme (04 §5); optionally Dark Reader for web pages.
- Resolve the duplicate ARZOPA monitor rule (07).
- Optional `plymouth-quit --retain-splash` drop-in for a smoother handoff to SDDM.
- Investigate the slow amdgpu load (~4.5 s, TSC unstable → HPET).
- A waybar pill counting minimized windows; a visual Alt+Tab switcher.
- Secure Boot (above).
