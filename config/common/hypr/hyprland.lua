-- wayland-desktop: common Hyprland config (programs, keys, autostart)
-- The look is in style.lua (a link to the active style, switched by wd-style)
-- ~/.config/hypr/user.lua is yours (kept by the installer): keyboard layout, monitors, any override

local home     = os.getenv("HOME")
local terminal = "kitty"
local launcher = "wofi --show drun"
local wd_style = home .. "/.local/bin/wd-style"
local mainMod  = "SUPER"

-- Load ~/.config/hypr/<name>.lua when it exists (dofile, or require when dofile is not available)
local function load(name)
    if not pcall(dofile, home .. "/.config/hypr/" .. name .. ".lua") then
        pcall(require, name)
    end
end

local function style(command)
    return hl.dsp.exec_cmd(wd_style .. " " .. command)
end

-- the overview (quickshell) answers a global shortcut at once; without quickshell: the wofi launcher (wd-style)
-- (looked up in the PATH: os.execute always fails in Hyprland, which reaps its children itself)
local function installed(program)
    for dir in (os.getenv("PATH") or "/usr/bin"):gmatch("[^:]+") do
        local file = io.open(dir .. "/" .. program, "r")

        if file then
            file:close()
            return true
        end
    end
    return false
end

local has_shell = installed("quickshell")

local function overview(name)
    if has_shell then
        return hl.dsp.global("wayland-desktop:" .. name)
    end
    return style(name)
end

------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1, -- "auto" picks 1.5 on many 1080p laptops: big and blurry XWayland apps (override in user.lua)
})

-------------------
---- AUTOSTART ----
-------------------

-- wd-style start: links of the active style, wallpaper, waybar, notifications (mako) and the overview (quickshell)
hl.on("hyprland.start", function()
    hl.exec_cmd(wd_style .. " start")
end)

hl.env("XCURSOR_THEME", "Adwaita")
hl.env("HYPRCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QS_ICON_THEME", "Adwaita")

---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout    = "us",
        follow_mouse = 2, -- GNOME: a click focuses, hovering a window doesn't (no flashing borders)
        touchpad     = {
            natural_scroll = true,
        },
    },

    general = {
        resize_on_border = true,
    },

    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        animate_manual_resizes   = false, -- a dragged or resized window follows the mouse at once
        animate_mouse_windowdragging = false,
        focus_on_activate        = true,
        allow_session_lock_restore = true, -- a locker that crashes can be replaced (hyprlock), never a dead lock
    },

    binds = {
        allow_workspace_cycles = true,
    },

    -- the cursor drawn by Hyprland: no ghost second cursor on hybrid Intel / NVIDIA laptops; the theme is not copied
    -- into gsettings (shared with GNOME: the animated cursors would show up in the GNOME session too)
    cursor = {
        no_hardware_cursors  = true,
        sync_gsettings_theme = false,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
        mfact      = 0.56,
    },
})

-- touchpad: 3 fingers sideways change of workspace, 4 fingers up the overview
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

hl.gesture({
    fingers   = 4,
    direction = "up",
    action    = function() hl.dispatch(overview("overview")) end,
})

---------------------
---- KEYBINDINGS ----
---------------------

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(launcher))
-- the file manager on this screen (wd-style: a GNOME session running next to this one would take its window)
hl.bind(mainMod .. " + E", style("files"))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + L", style("lock"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("hyprctl dispatch 'hl.dsp.exit()'"))

-- GNOME: Super alone (released without another key) the overview, Super twice or Super+A the applications
hl.bind(mainMod .. " + SUPER_L", overview("overview"), { release = true })
hl.bind(mainMod .. " + A", overview("apps"))
-- every key and control in a card
hl.bind(mainMod .. " + F1", overview("help"))

-- styles: menu / next, power menu, live or still wallpaper, art / mascot / normal cursor, radio shown or hidden (the
-- styles that hide it by default) (wd-style)
hl.bind(mainMod .. " + SHIFT + W", style("menu"))
hl.bind(mainMod .. " + ALT + W", style("next"))
hl.bind(mainMod .. " + X", style("power"))
hl.bind(mainMod .. " + SHIFT + B", style("wallpaper toggle"))
hl.bind(mainMod .. " + SHIFT + C", style("cursor next"))
hl.bind(mainMod .. " + SHIFT + M", style("radio toggle"))

-- notifications: show the last one again / dismiss them all
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("makoctl restore"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("makoctl dismiss --all"))

-- focus and move with the arrows
for _, direction in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mainMod .. " + " .. direction, hl.dsp.focus({ direction = direction }))
    hl.bind(mainMod .. " + SHIFT + " .. direction, hl.dsp.window.move({ direction = direction }))
end

-- workspaces 1-10 by key code (the number row of any layout: azerty, qwerty...)
for i = 1, 10 do
    local key = "code:" .. (9 + i)

    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- GNOME: previous / next workspace (Ctrl+Alt+arrows, Super+Page_Up/Down, Super+Alt+arrows), with the window (+ Shift)
local neighbours = {
    { keys = { "CTRL + ALT + left", "CTRL + ALT + up", mainMod .. " + Page_Up", mainMod .. " + ALT + left" },      workspace = "r-1" },
    { keys = { "CTRL + ALT + right", "CTRL + ALT + down", mainMod .. " + Page_Down", mainMod .. " + ALT + right" }, workspace = "r+1" },
}

for _, neighbour in ipairs(neighbours) do
    for _, key in ipairs(neighbour.keys) do
        local mods, name = key:match("^(.*) %+ ([^ ]+)$")

        hl.bind(key, hl.dsp.focus({ workspace = neighbour.workspace }))
        hl.bind(mods .. " + SHIFT + " .. name, hl.dsp.window.move({ workspace = neighbour.workspace }))
    end
end

-- back to the last workspace, windows of the workspace (Alt+Tab), scratchpad
hl.bind(mainMod .. " + Tab", hl.dsp.focus({ workspace = "previous" }))
hl.bind("ALT + Tab", hl.dsp.window.cycle_next())
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:scratchpad" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- screenshots: a zone to the clipboard, the whole screen to ~/Pictures
hl.bind("Print", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("mkdir -p ~/Pictures && grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"))

-- media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })

-------------------------
---- WINDOWS, LAYERS ----
-------------------------

-- small tools float in the middle (and the dialogs of the radio of the wallpaper), picture in picture stays on top
hl.window_rule({
    name   = "wd-float-tools",
    match  = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|nm-connection-editor|blueman-manager|org.gnome.Calculator|xdg-desktop-portal-gtk|wd-wallpaper)$" },
    float  = true,
    center = true,
    size   = "900 600",
})

-- the monitor and settings opened from the bar (wd-style monitor / settings)
hl.window_rule({
    name   = "wd-float-popups",
    match  = { class = "^(wd-float)$" },
    float  = true,
    center = true,
    size   = "1100 680",
})

hl.window_rule({
    name  = "wd-pip",
    match = { title = "^(Picture-in-Picture|Picture in picture)$" },
    float = true,
    pin   = true,
    keep_aspect_ratio = true,
})

-- the bar, the menus and the notifications blur what is behind them (the overview draws its own blurred wallpaper)
for _, namespace in ipairs({ "waybar", "wofi", "notifications" }) do
    hl.layer_rule({
        name         = "wd-blur-" .. namespace,
        match        = { namespace = namespace },
        blur         = true,
        ignore_alpha = 0.2,
    })
end

-- the overview and the live wallpaper animate themselves
for _, namespace in ipairs({ "wd-overview", "wd-wallpaper" }) do
    hl.layer_rule({
        name    = "wd-no-anim-" .. namespace,
        match   = { namespace = namespace },
        no_anim = true,
    })
end

---------------------
---- STYLE, USER ----
---------------------

load("style")
load("user")
