# 07 · Keyboard, monitors, window management

## Packages in this chapter

| Package | Role |
|---|---|
| `hyprland` | Keyboard layouts (`kb_layout`, `kb_options`), monitor rules, Alt+Tab and the minimize binds all live in its config |
| `xkeyboard-config` (dependency) | Defines the `us` and `ara` layouts and the `grp:win_space_toggle` switch |
| `python` | Runs the waybar keyboard-layout module (`kb-layout.py`) and parses `hyprctl -j` output in the minimize script |
| `wofi` | Picker for restoring minimized windows |

## 1. English + Arabic layouts

In `hyprland.lua` → `input`:
```lua
kb_layout  = "us,ara",
kb_options = "grp:win_space_toggle",   -- SUPER+Space switches layout
```
- **SUPER+Space** was chosen over Alt+Shift, which would collide with Alt+Shift+Tab.
- Test it: `hyprctl switchxkblayout all next`, then `hyprctl devices | grep 'active keymap'`.
- **Waybar pill:** the custom module `~/.config/waybar/scripts/kb-layout.py` shows `EN` in magenta or `ع` in orange (03).
- **Lock screen:** has a clickable `$LAYOUT` label (05). The password is typed in the active layout.
- **SDDM** always uses English.

## 2. Monitors

Inspect: `hyprctl monitors all` (names, descriptions, modes, scale, position).

Current logic in `hyprland.lua`:

| Situation | Layout |
|---|---|
| External (`HDMI-A-1`) connected | External at `0x0`, scale 1. Laptop to its right at `1920x0`, scale 1.25 |
| …and **SUPER+SHIFT+D** pressed | External only: the laptop panel is disabled. The state is stored in `~/.cache/hypr-single-screen`, and pressing it again restores both |
| No external screen | Laptop at `0x0`, scale 1 |

- The layout is applied at startup and re-applied on `hl.on("monitor.added")` and `hl.on("monitor.removed")`, with a 500 ms re-check because the removed output can still be listed briefly.
- **Wallpaper:** hyprpaper needs a `wallpaper {}` block for each monitor (02).
- **Lua config means `hyprctl keyword` doesn't work.** Use `hyprctl eval`, which applies until the next `hyprctl reload`:
  ```bash
  hyprctl eval 'hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto", scale = 1, mirror = "eDP-1" })'  # mirror
  hyprctl eval 'hl.monitor({ output = "HDMI-A-1", disabled = true })'                                                     # off
  ```
- **Other `hl.monitor` fields:** `transform` (rotation), `vrr`, `bitdepth`, `position = "auto-left|auto-right|auto-up|auto-down"`.

> ⚠️ **Known overlap:** below the dual-screen logic there is still an older rule, `desc:GWD ARZOPA 0000001692391` → `auto-left`, scale 1.25. It contradicts the newer layout (external at `0x0`, scale 1). Keep one of the two.

## 3. Alt+Tab

```lua
hl.bind("ALT+Tab",       hl.dsp.window.cycle_next(),                  { repeating = true })
hl.bind("ALT+SHIFT+Tab", hl.dsp.window.cycle_next({ next = false }), { repeating = true })
```
- It cycles windows on the **current workspace**.
- Adding `bring_to_top()` to the bind scrambled the reverse order, so it's left out.

## 4. Minimize

Hyprland has no minimize, so this emulates it:
- **SUPER+H** moves the window to the hidden `special:minimized` workspace with `follow = false`. (`silent = true` is ignored and pops the special workspace open.)
- **SUPER+SHIFT+H** runs `~/.local/bin/minimized restore` ([files/.local/bin/minimized](files/.local/bin/minimized)): a wofi list of minimized windows. The one you pick comes back to the current workspace and gets focus.
- **App minimize buttons** (e.g. Chrome's `–`) can't be hooked: Hyprland 0.56 sends no event for them.

## 5. Other window keys

| Keys | Action |
|---|---|
| SUPER+F / SUPER+CTRL+F | Fullscreen / maximize |
| SUPER+SHIFT+F | Toggle floating |
| SUPER+S / SUPER+SHIFT+S | Scratchpad show/hide / send window to it |
| SUPER+left/right-drag | Move / resize |
