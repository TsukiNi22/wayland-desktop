-- wayland-desktop style: Ado / blue rose (from the jpop POC), loaded by ~/.config/hypr/hyprland.lua

hl.config({
    general = {
        gaps_in     = 8,
        gaps_out    = 18,
        border_size = 3,
        col = {
            active_border   = { colors = { "rgba(2f6bffee)", "rgba(9fc3ffee)", "rgba(ffffffcc)", "rgba(2f6bffee)" }, angle = 45 },
            inactive_border = "rgba(223a7aaa)",
        },
        layout = "dwindle",
    },

    decoration = {
        rounding         = 18,
        rounding_power   = 2.5,
        active_opacity   = 1.0,
        inactive_opacity = 0.9,
        dim_inactive     = true,
        dim_strength     = 0.18,
        dim_special      = 0.35,

        shadow = {
            enabled        = true,
            range          = 30,
            render_power   = 3,
            color          = 0x772f6bff,
            color_inactive = 0x44000000,
        },

        -- neon halo around the active window
        glow = {
            enabled        = true,
            range          = 18,
            render_power   = 3,
            color          = "rgba(2f6bff55)",
            color_inactive = "rgba(00000000)",
        },

        blur = {
            enabled  = true,
            size     = 8,
            passes   = 3,
            noise    = 0.01,
            vibrancy = 0.35,
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

hl.animation({ leaf = "windowsIn",        enabled = true, speed = 5, bezier = "wd_back", style = "popin 70%" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 3, bezier = "wd_smooth", style = "popin 80%" })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 5, bezier = "wd_back" })
hl.animation({ leaf = "fade",             enabled = true, speed = 4, bezier = "wd_smooth" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 6, bezier = "wd_smooth", style = "slidefade 30%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "wd_smooth", style = "slidefadevert 30%" })
hl.animation({ leaf = "border",           enabled = true, speed = 8, bezier = "wd_smooth" })
hl.animation({ leaf = "borderangle",      enabled = true, speed = 35, bezier = "wd_linear", style = "loop" })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 4, bezier = "wd_back", style = "popin 85%" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 2.5, bezier = "wd_smooth", style = "fade" })

-- the bar slides in from its edge (at the start and when the style changes)
hl.layer_rule({
    name      = "wd-bar-slide",
    match     = { namespace = "waybar" },
    animation = "slide top",
})
