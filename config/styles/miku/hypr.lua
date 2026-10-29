-- wayland-desktop style: Miku (from the miku POC), loaded by ~/.config/hypr/hyprland.lua

hl.config({
    general = {
        gaps_in     = 8,
        gaps_out    = 16,
        border_size = 3,
        col = {
            active_border   = { colors = { "rgba(39c5bbee)", "rgba(e12885ee)", "rgba(39c5bbee)" }, angle = 45 },
            inactive_border = "rgba(1f6f6aaa)",
        },
        layout = "dwindle",
    },

    decoration = {
        rounding         = 14,
        rounding_power   = 3.0,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        dim_inactive     = false,
        dim_strength     = 0.12,
        dim_special      = 0.35,

        shadow = {
            enabled        = true,
            range          = 24,
            render_power   = 3,
            color          = 0x6639c5bb,
            color_inactive = 0x44000000,
        },

        -- neon halo around the active window
        glow = {
            enabled        = true,
            range          = 16,
            render_power   = 3,
            color          = "rgba(39c5bb55)",
            color_inactive = "rgba(00000000)",
        },

        blur = {
            enabled  = true,
            size     = 6,
            passes   = 3,
            noise    = 0.01,
            vibrancy = 0.3,
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

hl.animation({ leaf = "windowsIn",        enabled = true, speed = 4.5, bezier = "wd_back", style = "popin 60%" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 2.5, bezier = "wd_smooth", style = "popin 70%" })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 4, bezier = "wd_smooth" })
hl.animation({ leaf = "fade",             enabled = true, speed = 3, bezier = "wd_smooth" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 5, bezier = "wd_smooth", style = "slidefadevert 25%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "wd_smooth", style = "slidefadevert 40%" })
hl.animation({ leaf = "border",           enabled = true, speed = 5, bezier = "wd_smooth" })
hl.animation({ leaf = "borderangle",      enabled = true, speed = 25, bezier = "wd_linear", style = "loop" })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 3.5, bezier = "wd_back", style = "popin 80%" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 2, bezier = "wd_smooth", style = "fade" })

-- the bar slides in from its edge (at the start and when the style changes)
hl.layer_rule({
    name      = "wd-bar-slide",
    match     = { namespace = "waybar" },
    animation = "slide top",
})
