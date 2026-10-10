# 06 · Terminal

## 1. kitty

Copy [`files/.config/kitty/kitty.conf`](files/.config/kitty/kitty.conf):
- JetBrainsMono Nerd Font 11.5, `background_opacity 0.82` (blurred by Hyprland), padding 12, beam cursor with a trail
- the full Tokyo Night 16-colour palette, powerline tab bar
- **Clipboard:** `map ctrl+c copy_or_interrupt` copies when text is selected, otherwise sends ^C as usual. `map ctrl+v paste_from_clipboard`. Ctrl+Shift+C/V still work.

Reload running windows: `pkill -USR1 -x kitty`.

## 2. Starship prompt (powerline)

```bash
sudo pacman -S starship
cp files/.config/starship.toml ~/.config/
```
- Two-line prompt: `╭─` [Arch logo + user] ▶ [folder] ▶ [git branch/status + language versions + command duration] ◗, then `╰─❯`.
- The `❯` is green after success, red after failure.
- All powerline glyphs are written by codepoint (``, ``…).
- Git and duration share one segment colour, so empty segments don't leave stacked arrows.

## 3. fastfetch with a nixie-tube logo

```bash
mkdir -p ~/.config/fastfetch
cp files/.config/fastfetch/{config.jsonc,divergence.txt} ~/.config/fastfetch/
```
- `divergence.txt` is an ASCII divergence meter: 8 box-drawn tubes reading 1.048596, coloured with `$1`/`$2`/`$3` (glass / nixie orange / base).
- Key column width is **15**. At 12, the values overwrote the longer labels.
- It runs once per kitty window, from `~/.bashrc` (not in tmux or nested shells).

## 4. eza, bat, btop, tmux, bashrc

```bash
cp files/.bashrc ~/                     # eza/bat aliases, MANPAGER via bat, fastfetch, starship init
cp files/.tmux.conf ~/
mkdir -p ~/.config/btop ~/.config/bat/themes
cp files/.config/btop/btop.conf ~/.config/btop/
cp files/.config/bat/config ~/.config/bat/
curl -fsSL -o ~/.config/bat/themes/tokyonight_night.tmTheme \
  https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/sublime/tokyonight_night.tmTheme
bat cache --build && bat --list-themes | grep tokyo
```

| Tool | Setup |
|---|---|
| eza | `ls` (icons, folders first), `ll` (git + relative times), `la`, `lt` (tree, 2 levels) |
| bat | Official Tokyo Night theme. `cat` is aliased to `bat --paging=never --style=plain` (use `\cat` for the real one). Man pages are coloured |
| btop | Built-in `tokyo-night` theme, transparent background. **SUPER+SHIFT+Escape** opens it in an 85% floating window, because btop needs ≥80 columns and a half tile is only 62 |
| tmux | Prefix **Ctrl+a**, `\|`/`-` split in the current folder, `r` reloads, mouse on, Tokyo Night powerline status bar at the top |

Testing tip: eza drops icons and colours when its output is piped (`| head`), so test it in a real terminal.
