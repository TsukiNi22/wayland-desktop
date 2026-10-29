-- wayland-desktop style: Photographer (from the photographer POC), loaded by ~/.config/hypr/hyprland.lua

hl.config({
    general = {
        gaps_in     = 12,
        gaps_out    = 28,
        border_size = 1,
        col = {
            active_border   = { colors = { "rgba(d9a441ff)" }, angle = 45 },
            inactive_border = "rgba(34312ccc)",
        },
        layout = "dwindle",
    },

    decoration = {
        rounding         = 10,
        rounding_power   = 2.0,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        dim_inactive     = true,
        dim_strength     = 0.08,
        dim_special      = 0.35,

        shadow = {
            enabled        = true,
            range          = 40,
            render_power   = 3,
            color          = 0x99000000,
            color_inactive = 0x44000000,
        },

        blur = {
            enabled  = true,
            size     = 5,
            passes   = 2,
            noise    = 0.05,
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
hl.curve("wd_back",      { type = "bezier", points = { {0.34, 1.4}, {0.64, 1} } })
hl.curve("wd_soft",      { type = "bezier", points = { {0.45, 0}, {0.25, 1} } })
hl.curve("wd_linear",    { type = "bezier", points = { {0, 0}, {1, 1} } })

hl.animation({ leaf = "windowsIn",        enabled = true, speed = 7, bezier = "wd_soft", style = "popin 96%" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 4, bezier = "wd_soft", style = "popin 96%" })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 6, bezier = "wd_soft" })
hl.animation({ leaf = "fade",             enabled = true, speed = 6, bezier = "wd_soft" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 8, bezier = "wd_soft", style = "fade" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 6, bezier = "wd_soft", style = "fade" })
hl.animation({ leaf = "border",           enabled = true, speed = 8, bezier = "wd_soft" })
hl.animation({ leaf = "borderangle",      enabled = false })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 5, bezier = "wd_soft", style = "fade" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 3, bezier = "wd_soft", style = "fade" })

-- the bar slides in from its edge (at the start and when the style changes)
hl.layer_rule({
    name      = "wd-bar-slide",
    match     = { namespace = "waybar" },
    animation = "slide top",
})
