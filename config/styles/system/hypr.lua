-- wayland-desktop style: System (from the system POC), loaded by ~/.config/hypr/hyprland.lua

hl.config({
    general = {
        gaps_in     = 6,
        gaps_out    = 14,
        border_size = 2,
        col = {
            active_border   = { colors = { "rgba(5aa9ffee)", "rgba(5fd38dee)", "rgba(5aa9ffee)" }, angle = 45 },
            inactive_border = "rgba(2a3441aa)",
        },
        layout = "dwindle",
    },

    decoration = {
        rounding         = 14,
        rounding_power   = 2.5,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        dim_inactive     = false,
        dim_strength     = 0.1,
        dim_special      = 0.35,

        shadow = {
            enabled        = true,
            range          = 24,
            render_power   = 3,
            color          = 0x66000000,
            color_inactive = 0x44000000,
        },

        blur = {
            enabled  = true,
            size     = 6,
            passes   = 3,
            noise    = 0.01,
            vibrancy = 0.2,
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

hl.animation({ leaf = "windowsIn",        enabled = true, speed = 4, bezier = "wd_overshoot", style = "gnomed" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 2.5, bezier = "wd_smooth", style = "gnomed" })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 4, bezier = "wd_smooth" })
hl.animation({ leaf = "fade",             enabled = true, speed = 3, bezier = "wd_smooth" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 4.5, bezier = "wd_snap", style = "slidefade 15%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "wd_snap", style = "slidefadevert 20%" })
hl.animation({ leaf = "border",           enabled = true, speed = 6, bezier = "wd_smooth" })
hl.animation({ leaf = "borderangle",      enabled = true, speed = 80, bezier = "wd_linear", style = "loop" })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 3, bezier = "wd_overshoot", style = "popin 92%" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 2, bezier = "wd_smooth", style = "fade" })

-- the bar slides in from its edge (at the start and when the style changes)
hl.layer_rule({
    name      = "wd-bar-slide",
    match     = { namespace = "waybar" },
    animation = "slide top",
})
