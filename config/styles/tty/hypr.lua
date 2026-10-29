-- wayland-desktop style: Terminal / better-tty (from the tty POC), loaded by ~/.config/hypr/hyprland.lua

hl.config({
    general = {
        gaps_in     = 0,
        gaps_out    = 0,
        border_size = 3,
        col = {
            active_border   = { colors = { "rgba(c4a7e7ff)" }, angle = 45 },
            inactive_border = "rgba(403d52cc)",
        },
        layout = "master",
    },

    decoration = {
        rounding         = 0,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        dim_inactive     = false,
        dim_strength     = 0.0,

        shadow = {
            enabled      = false,
            range        = 22,
            render_power = 3,
            color        = 0x88000000,
        },

        blur = {
            enabled  = false,
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

hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4,   bezier = "wd_overshoot", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2,   bezier = "wd_smooth",    style = "popin 85%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4,  bezier = "wd_overshoot" })
hl.animation({ leaf = "fade",       enabled = true, speed = 3,   bezier = "wd_smooth" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3.5, bezier = "wd_overshoot", style = "fade" })
hl.animation({ leaf = "border",     enabled = true, speed = 5,   bezier = "wd_smooth" })
hl.animation({ leaf = "borderangle", enabled = false })
