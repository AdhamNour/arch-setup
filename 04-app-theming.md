# 04 · App theming: GTK, Qt, icons, cursor, fonts, Chrome

## Packages in this chapter

| Package | Role |
|---|---|
| `tokyonight-gtk-theme-git` (AUR) | Tokyo Night theme for GTK 3/4 apps (Thunar, pavucontrol, file dialogs, blueman) |
| `papirus-icon-theme` | Papirus-Dark icon set for apps, folders and wofi |
| `papirus-folders` (AUR) | Recolours Papirus folder icons (set to indigo) |
| `bibata-cursor-theme-bin` (AUR) | Bibata-Modern-Ice mouse cursor |
| `qt6ct` | Lets Qt 6 apps use a chosen style, icons and fonts outside KDE |
| `kvantum` | Qt style engine. Runs the custom TokyoNight theme (recoloured KvArcDark) |
| `nwg-look` | Optional GUI for GTK settings (all set here with gsettings instead) |
| `fontconfig` (dependency) | Font matching. The user rule makes Arabic fall back to Noto Naskh |
| `noto-fonts` | Provides Noto Naskh Arabic, Noto Sans, Noto Serif |
| `google-chrome` (AUR) | The browser themed by the unpacked Tokyo Night theme |

## 1. GTK 3/4 + libadwaita

```bash
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
cp files/.config/gtk-3.0/{settings.ini,gtk.css} ~/.config/gtk-3.0/
cp files/.config/gtk-4.0/settings.ini ~/.config/gtk-4.0/
# libadwaita apps ignore gtk-theme-name: link the theme's gtk-4.0 CSS
for f in gtk.css gtk-dark.css assets; do ln -sfn /usr/share/themes/Tokyonight-Dark/gtk-4.0/$f ~/.config/gtk-4.0/$f; done
gsettings set org.gnome.desktop.interface gtk-theme 'Tokyonight-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'
gsettings set org.gnome.desktop.interface cursor-size 24
gsettings set org.gnome.desktop.interface font-name 'Noto Sans 10'
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
```
`~/.config/gtk-3.0/gtk.css` fixes a Tokyonight-Dark bug: **Thunar's selected sidebar row was almost white**, so its text was unreadable. The override makes it soft blue.

## 2. Icons and cursor

```bash
sudo papirus-folders -C indigo --theme Papirus-Dark      # folder colour closest to #7aa2f7
mkdir -p ~/.icons/default && cp files/.icons/default/index.theme ~/.icons/default/
hyprctl setcursor Bibata-Modern-Ice 24
```
The cursor env vars are set in `hyprland.lua` (01).

## 3. Qt: qt6ct + a Tokyo Night Kvantum theme

Kvantum ships no Tokyo Night theme. `files/.config/Kvantum/TokyoNight/` was made by **recolouring KvArcDark**: each grey was mapped to the nearest Tokyo Night shade by brightness, the blues to `#7aa2f7`, and text to `#c0caf5`.
```bash
cp -r files/.config/Kvantum ~/.config/
mkdir -p ~/.config/qt6ct && cp files/.config/qt6ct/qt6ct.conf ~/.config/qt6ct/
```
- `qt6ct.conf` uses `style=kvantum` with Papirus-Dark icons.
- **Kvantum's `translucent_windows`/`blurring` are off**: they only work on KDE, and Hyprland handles blur instead.
- **Don't set `QT_SCALE_FACTOR` globally**: it double-scales Wayland Qt apps.
- **Apps must be relaunched by Hyprland** to pick up the env vars. That includes the polkit agent, so restart it with `hyprctl dispatch 'hl.dsp.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")'`. **Don't use `pkill -f`**: it matches its own shell command line and kills it.

## 4. Arabic font: Noto Naskh instead of Kufi

Neither JetBrains Mono nor Noto Sans has Arabic glyphs, so fontconfig fell back to **Noto Kufi Arabic** (blocky).
```bash
mkdir -p ~/.config/fontconfig/conf.d
cp files/.config/fontconfig/conf.d/60-arabic-naskh.conf ~/.config/fontconfig/conf.d/
fc-cache -f
fc-match 'sans-serif:lang=ar'     # → Noto Naskh Arabic UI
```
- The file puts Naskh straight after the Latin font in the sans-serif, serif and monospace lists.
- It also **rejects the Noto Sans Arabic family**. `/etc/fonts/conf.d/65-nonlatin.conf` runs *after* user config and gives "Segoe UI"/system-UI requests Noto Sans Arabic UI. Hiding that family makes them fall back to Naskh too. Noto Kufi still works when a page asks for it by name.
- **Restart Chrome fully** (Ctrl+Q) afterwards.

## 5. Chrome theme (unpacked theme)

[`files/.local/share/chrome-themes/tokyo-night-steins-gate/manifest.json`](files/.local/share/chrome-themes/tokyo-night-steins-gate/manifest.json) is a manifest v3 theme:
- tab strip `#16161e`, toolbar `#1a1b26`, blue icons, dark address bar
- divergence wallpaper on the new tab page, at `images/ntp_background.png`
```bash
T=~/.local/share/chrome-themes/tokyo-night-steins-gate; mkdir -p $T/images
cp files/.local/share/chrome-themes/tokyo-night-steins-gate/manifest.json $T/
cp ~/Pictures/wallpapers/steins-gate-divergence.png $T/images/ntp_background.png
```
Then:
1. Open `chrome://extensions`, turn on **Developer mode**, click **Load unpacked** and pick the folder (Ctrl+H shows hidden folders).
2. In `chrome://settings/appearance`, set Mode to **Dark**. If Theme says "GTK", reset it first, because GTK mode ignores custom themes.

Notes:
- Chrome 137+ ignores `--load-extension`, and themes from outside the Web Store must be loaded unpacked. Keep Developer mode on.
- *Current state:* Chrome is using a colour picked in Chrome's own theme settings (`autogenerated_theme_id`). The unpacked theme is ready but wasn't loaded.
