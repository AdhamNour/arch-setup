-- Make ~/.local/bin (screenshot, emulator wrappers) available no matter how Hyprland was
-- started (SDDM does not run ~/.bash_profile)
do
    local home = os.getenv("HOME") or "/home/adham"
    local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
    if not path:find(home .. "/.local/bin", 1, true) then
        hl.env("PATH", home .. "/.local/bin:" .. path)
    end
end

hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")

-- Qt apps: follow qt6ct (Kvantum Tokyo Night style + Papirus icons)
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- External (HDMI-A-1) plugged in: only it is active. Otherwise the laptop panel is.
local LAPTOP   = "eDP-1"
local EXTERNAL = "HDMI-A-1"

-- SUPER+SHIFT+D flips this state file and reloads. Re-enabling a disabled panel
-- only takes effect on a config reload, so the state must survive reloads.
local STATE_FILE = (os.getenv("HOME") or "/home/adham") .. "/.cache/hypr-single-screen"
local both_screens = true
do
    local f = io.open(STATE_FILE, "r")
    if f then f:close(); both_screens = false end
end

local function apply_layout()
    if hl.get_monitor(EXTERNAL) ~= nil then
        hl.monitor({ output = EXTERNAL, mode = "1920x1080@60", position = "0x0", scale = 1 })
        if both_screens then
            hl.monitor({ output = LAPTOP, mode = "preferred", position = "1920x0", scale = 1.25 })
        else
            hl.monitor({ output = LAPTOP, disabled = true })
        end
    else
        hl.monitor({ output = LAPTOP, mode = "preferred", position = "0x0", scale = 1 })
    end
end

apply_layout()
hl.on("monitor.added", apply_layout)
-- Re-check shortly after removal: the output may still be listed while the event fires
hl.on("monitor.removed", function()
    apply_layout()
    hl.timer(apply_layout, { timeout = 500, type = "oneshot" })
end)

-- ARZOPA portable screen (matched by description, so any port works): left of the laptop
hl.monitor({
    output   = "desc:GWD ARZOPA 0000001692391",
    mode     = "1920x1080@60",
    position = "auto-left",
    scale    = 1.25,
})

-- Tokyo Night palette
local tn = {
    bg        = "1a1b26",
    bg_dark   = "16161e",
    bg_hl     = "292e42",
    fg        = "c0caf5",
    comment   = "565f89",
    blue      = "7aa2f7",
    cyan      = "7dcfff",
    magenta   = "bb9af7",
    orange    = "ff9e64",
}

hl.config({
    general = {
        gaps_in = 8,
        gaps_out = 16,
        border_size = 2,
        layout = "dwindle",
        resize_on_border = true,
        col = {
            active_border   = { colors = { "rgba(" .. tn.blue .. "ff)", "rgba(" .. tn.magenta .. "ff)" }, angle = 45 },
            inactive_border = "rgba(" .. tn.bg_hl .. "cc)",
        },
    },
    decoration = {
        rounding = 12,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 0.92,
        shadow = {
            enabled = true,
            range = 18,
            render_power = 3,
            color = 0xaa0f0f17,
        },
        blur = {
            enabled = true,
            size = 8,
            passes = 3,
            vibrancy = 0.18,
            noise = 0.02,
            popups = true,
        },
    },
    dwindle = {
        preserve_split = true,
    },
    input = {
        kb_layout = "us,ara",               -- English, Arabic
        kb_options = "grp:win_space_toggle", -- SUPER+Space switches layout
        follow_mouse = 1,
        touchpad = {
            natural_scroll = true,
        },
    },
    -- Let XWayland apps (Android emulator, Java apps) render at native resolution
    -- instead of being upscaled 1.5x (which makes them blurry)
    xwayland = {
        force_zero_scaling = true,
    },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
    },
})

-- Animations: springy windows, sliding workspaces, quick layer fades (nothing over ~400 ms)
hl.config({ animations = { enabled = true } })

hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeOutExpo",  { type = "bezier", points = { {0.16, 1},    {0.3, 1}  } })
hl.curve("almostLinear", { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("linear",       { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("snappy",       { type = "spring", mass = 1, stiffness = 300, dampening = 26 })
hl.curve("bouncy",       { type = "spring", mass = 1, stiffness = 260, dampening = 20 })

hl.animation({ leaf = "global",        enabled = true, speed = 8,   bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.5, spring = "snappy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4,   spring = "bouncy", style = "popin 85%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 2,   bezier = "easeOutExpo", style = "popin 90%" })
hl.animation({ leaf = "windowsMove",   enabled = true, speed = 4,   spring = "snappy" })
hl.animation({ leaf = "border",        enabled = true, speed = 5,   bezier = "easeOutQuint" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 2,   bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.8, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3,   bezier = "easeOutQuint" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.5, bezier = "easeOutExpo" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 3.5, bezier = "easeOutExpo", style = "slide" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 2,   bezier = "easeOutExpo", style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 2,   bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.6, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 3.5, bezier = "easeOutExpo", style = "slidefade 15%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3.5, bezier = "easeOutExpo", style = "slidefadevert 20%" })

-- Blur behind the bar, launcher and notifications
hl.layer_rule({ name = "blur-waybar", match = { namespace = "^waybar$" },        blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "blur-wofi",   match = { namespace = "^wofi$" },          blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "blur-swaync",  match = { namespace = "^swaync-(control-center|notification-window)$" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "blur-wlogout", match = { namespace = "^logout_dialog$" }, blur = true })
hl.layer_rule({ name = "no-anim-slurp", match = { namespace = "^selection$" }, no_anim = true })

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("swaync")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
end)

local mainMod = "SUPER"

hl.bind(mainMod .. "+Q", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. "+C", hl.dsp.window.close())
hl.bind(mainMod .. "+M", hl.dsp.exec_cmd("wlogout -b 5 -p layer-shell"))
hl.bind(mainMod .. "+Escape", hl.dsp.exec_cmd("wlogout -b 5 -p layer-shell"))
hl.bind(mainMod .. "+L", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(mainMod .. "+E", hl.dsp.exec_cmd("thunar"))
hl.bind(mainMod .. "+R", hl.dsp.exec_cmd("wofi --show drun"))
hl.bind(mainMod .. "+SHIFT+F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. "+F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mainMod .. "+CTRL+F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mainMod .. "+V", hl.dsp.exec_cmd("cliphist list | wofi --dmenu --prompt clipboard --cache-file /dev/null | cliphist decode | wl-copy"))
hl.bind(mainMod .. "+N", hl.dsp.exec_cmd("swaync-client -t -sw"))

-- "Minimize": hide the window on a hidden workspace; SUPER+SHIFT+H picks one to bring back
hl.bind(mainMod .. "+H",       hl.dsp.window.move({ workspace = "special:minimized", follow = false }))
hl.bind(mainMod .. "+SHIFT+H", hl.dsp.exec_cmd("minimized restore"))

-- Alt+Tab / Alt+Shift+Tab: cycle windows on the current workspace
hl.bind("ALT+Tab",       hl.dsp.window.cycle_next(),                  { repeating = true })
hl.bind("ALT+SHIFT+Tab", hl.dsp.window.cycle_next({ next = false }), { repeating = true })
hl.bind(mainMod .. "+SHIFT+D", hl.dsp.exec_cmd(
    "sh -c 'f=" .. STATE_FILE .. "; if [ -e \"$f\" ]; then rm -f \"$f\"; else touch \"$f\"; fi; hyprctl reload'"))
hl.bind(mainMod .. "+SHIFT+Escape", hl.dsp.exec_cmd("kitty --class btop -e btop"))

hl.bind("Print",                 hl.dsp.exec_cmd("screenshot full"))
hl.bind("SHIFT+Print",           hl.dsp.exec_cmd("screenshot area"))
hl.bind(mainMod .. "+SHIFT+Print", hl.dsp.exec_cmd("screenshot window"))
hl.bind(mainMod .. "+SHIFT+P",   hl.dsp.exec_cmd("screenshot area"))  -- for keyboards without Print
hl.bind(mainMod .. "+P", hl.dsp.window.pseudo())
hl.bind(mainMod .. "+J", hl.dsp.layout("togglesplit"))

hl.bind(mainMod .. "+left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. "+right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. "+up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. "+down",  hl.dsp.focus({ direction = "down" }))

-- Workspaces 1-10 (key 0 = workspace 10); SHIFT moves the active window there
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. "+" .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. "+SHIFT+" .. key,   hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. "+S",       hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. "+SHIFT+S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. "+mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. "+mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. "+mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. "+mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s +5%"),                            { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 5%-"),                            { locked = true, repeating = true })

hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Android emulator: float at its own size instead of being stretched into a tile
hl.window_rule({
    name  = "float-android-emulator",
    match = { class = "^Emulator$" },
    float = true,
})

-- Bluetooth manager: small floating window
hl.window_rule({
    name  = "float-blueman",
    match = { class = "^(blueman-manager|\\.blueman-manager-wrapped)$" },
    float = true,
    size  = "560 440",
    center = true,
})

-- System monitor (SUPER+SHIFT+Escape): big floating window so btop has room
hl.window_rule({
    name  = "float-btop",
    match = { class = "^btop$" },
    float = true,
    size  = "monitor_w*0.85 monitor_h*0.85",
    center = true,
})
