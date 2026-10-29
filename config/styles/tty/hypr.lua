-- wayland-desktop style: Terminal / better-tty (from the tty POC), loaded by ~/.config/hypr/hyprland.lua

hl.config({
    general = {
        gaps_in     = 3,
        gaps_out    = 6,
        border_size = 2,
        col = {
            active_border   = { colors = { "rgba(c4a7e7ff)", "rgba(ebbcbaff)", "rgba(9ccfd8ff)", "rgba(c4a7e7ff)" }, angle = 45 },
            inactive_border = "rgba(403d52cc)",
        },
        layout = "master",
    },

    decoration = {
        rounding         = 10,
        rounding_power   = 2.5,
        active_opacity   = 1.0,
        inactive_opacity = 0.96,
        dim_inactive     = true,
        dim_strength     = 0.12,
        dim_special      = 0.35,

        shadow = {
            enabled        = true,
            range          = 12,
            render_power   = 3,
            color          = 0x55000000,
            color_inactive = 0x44000000,
        },

        blur = {
            enabled  = true,
            size     = 5,
            passes   = 2,
            noise    = 0.02,
            vibrancy = 0.15,
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
hl.curve("wd_back",      { type = "bezier", points = { {0.34, 1.4}, {0.64, 1} } })
hl.curve("wd_soft",      { type = "bezier", points = { {0.45, 0}, {0.25, 1} } })
hl.curve("wd_linear",    { type = "bezier", points = { {0, 0}, {1, 1} } })

hl.animation({ leaf = "windowsIn",        enabled = true, speed = 2.5, bezier = "wd_snap", style = "slide" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 2, bezier = "wd_snap", style = "slide" })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 2.5, bezier = "wd_snap" })
hl.animation({ leaf = "fade",             enabled = true, speed = 1.5, bezier = "wd_linear" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 3, bezier = "wd_snap", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "wd_snap", style = "slidevert" })
hl.animation({ leaf = "border",           enabled = true, speed = 3, bezier = "wd_linear" })
hl.animation({ leaf = "borderangle",      enabled = true, speed = 100, bezier = "wd_linear", style = "loop" })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 2.5, bezier = "wd_snap", style = "slide" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 1.5, bezier = "wd_snap", style = "fade" })

-- the bar slides in from its edge (at the start and when the style changes)
hl.layer_rule({
    name      = "wd-bar-slide",
    match     = { namespace = "waybar" },
    animation = "slide bottom",
})
