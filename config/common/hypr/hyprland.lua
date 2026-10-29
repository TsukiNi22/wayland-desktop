-- wayland-desktop: common Hyprland config (programs, keys, autostart)
-- The look is in style.lua (a link to the active style, switched by wd-style)
-- ~/.config/hypr/user.lua is yours (kept by the installer): keyboard layout, monitors, any override

local home     = os.getenv("HOME")
local terminal = "kitty"
local launcher = "wofi --show drun"
local files    = "nautilus"
local wd_style = home .. "/.local/bin/wd-style"
local mainMod  = "SUPER"

-- Load ~/.config/hypr/<name>.lua when it exists (dofile, or require when dofile is not available)
local function load(name)
    if not pcall(dofile, home .. "/.config/hypr/" .. name .. ".lua") then
        pcall(require, name)
    end
end

------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-------------------
---- AUTOSTART ----
-------------------

-- wd-style start: links of the active style, waybar and the wallpaper
hl.on("hyprland.start", function()
    hl.exec_cmd(wd_style .. " start")
    hl.exec_cmd("mako")
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout    = "us",
        follow_mouse = 1,
        touchpad     = {
            natural_scroll = true,
        },
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
        mfact      = 0.56,
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

---------------------
---- KEYBINDINGS ----
---------------------

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(launcher))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(files))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("hyprctl dispatch 'hl.dsp.exit()'"))

-- styles: menu / next (wd-style)
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(wd_style .. " menu"))
hl.bind(mainMod .. " + ALT + W", hl.dsp.exec_cmd(wd_style .. " next"))

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

---------------------
---- STYLE, USER ----
---------------------

load("style")
load("user")
