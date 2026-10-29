-- wayland-desktop style: Dev / low level (from the dev POC), loaded by ~/.config/hypr/hyprland.lua

hl.config({
    general = {
        gaps_in     = 4,
        gaps_out    = 8,
        border_size = 2,
        col = {
            active_border   = { colors = { "rgba(39ff88ff)", "rgba(1c4a2eff)", "rgba(39ff88ff)" }, angle = 45 },
            inactive_border = "rgba(1c4a2ecc)",
        },
        layout = "dwindle",
    },

    decoration = {
        rounding         = 6,
        rounding_power   = 2.0,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        dim_inactive     = false,
        dim_strength     = 0.18,
        dim_special      = 0.35,

        shadow = {
            enabled        = true,
            range          = 14,
            render_power   = 3,
            color          = 0x5539ff88,
            color_inactive = 0x44000000,
        },

        -- neon halo around the active window
        glow = {
            enabled        = true,
            range          = 14,
            render_power   = 3,
            color          = "rgba(39ff8866)",
            color_inactive = "rgba(00000000)",
        },

        blur = {
            enabled  = true,
            size     = 4,
            passes   = 2,
            noise    = 0.03,
            vibrancy = 0.1,
            popups   = true,
            special  = true,
        },
    },

    animations = {
        enabled = true,
    },
})

-- motion of the POC kit: one curve family per style (overshoot, snap, back, soft)
hl.curve("wd_overshoot", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.curve("wd_smooth",    { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("wd_snap",      { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })
hl.curve("wd_back",      { type = "bezier", points = { {0.34, 1.22}, {0.64, 1} } })
hl.curve("wd_soft",      { type = "bezier", points = { {0.45, 0}, {0.25, 1} } })
hl.curve("wd_linear",    { type = "bezier", points = { {0, 0}, {1, 1} } })

hl.animation({ leaf = "windowsIn",        enabled = true, speed = 3, bezier = "wd_snap", style = "slide" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 1.5, bezier = "wd_snap", style = "popin 95%" })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 3, bezier = "wd_snap" })
hl.animation({ leaf = "fade",             enabled = true, speed = 2, bezier = "wd_snap" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 3, bezier = "wd_snap", style = "slidevert" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "wd_snap", style = "slidefadevert 30%" })
hl.animation({ leaf = "border",           enabled = true, speed = 2, bezier = "wd_linear" })
hl.animation({ leaf = "borderangle",      enabled = true, speed = 40, bezier = "wd_linear", style = "loop" })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 2.5, bezier = "wd_snap", style = "slide" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 1.5, bezier = "wd_snap", style = "fade" })

-- the bar slides in from its edge (at the start and when the style changes)
hl.layer_rule({
    name      = "wd-bar-slide",
    match     = { namespace = "waybar" },
    animation = "slide top",
})
