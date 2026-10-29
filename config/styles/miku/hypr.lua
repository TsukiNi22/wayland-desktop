-- wayland-desktop style: Miku (from the miku POC), loaded by ~/.config/hypr/hyprland.lua

hl.config({
    general = {
        gaps_in     = 8,
        gaps_out    = 16,
        border_size = 3,
        col = {
            active_border   = { colors = { "rgba(39c5bbee)", "rgba(e12885ee)" }, angle = 45 },
            inactive_border = "rgba(1f6f6acc)",
        },
        layout = "dwindle",
    },

    decoration = {
        rounding         = 8,
        active_opacity   = 1.0,
        inactive_opacity = 0.95,
        dim_inactive     = true,
        dim_strength     = 0.12,

        shadow = {
            enabled      = true,
            range        = 22,
            render_power = 3,
            color        = 0x88000000,
        },

        blur = {
            enabled  = true,
            size     = 6,
            passes   = 2,
            vibrancy = 0.2,
        },
    },

    animations = {
        enabled = true,
    },
})

-- motion of the POC kit: windows pop in with an overshoot curve, workspaces slide like the scenes
hl.curve("wd_overshoot", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.curve("wd_smooth",    { type = "bezier", points = { {0.23, 1},   {0.32, 1}   } })
hl.curve("wd_linear",    { type = "bezier", points = { {0, 0},      {1, 1}      } })

hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4,   bezier = "wd_overshoot", style = "popin 70%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2,   bezier = "wd_smooth",    style = "popin 85%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4,  bezier = "wd_overshoot" })
hl.animation({ leaf = "fade",       enabled = true, speed = 3,   bezier = "wd_smooth" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3.5, bezier = "wd_overshoot", style = "slide" })
hl.animation({ leaf = "border",     enabled = true, speed = 5,   bezier = "wd_smooth" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 60, bezier = "wd_linear", style = "loop" })
