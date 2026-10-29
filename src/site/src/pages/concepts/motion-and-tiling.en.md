+++
title = "Motion and tiling"
summary = "The Hyprland-like animations, the floating and tiling layouts, and how a scene opens its windows."
section = "concepts"
order = 2
keywords = "animation motion hyprland popin overshoot tiling layout gaps scene workspace glow dim"
+++

The motion copies what Hyprland rices do; the layouts and the scenes are a few functions of the kit.

## Hyprland-like motion {#motion}

| Effect | How |
|---|---|
| A window opens | grows from 80 % with the overshoot curve `cubic-bezier(0.05, 0.9, 0.1, 1.05)` (`--k-open`, `--k-ease`) |
| A window closes / minimizes | shrinks / drops and fades in 0.2 s before hiding |
| The scene changes | the windows slide in like a workspace switch |
| Active window (`body.k-glow`) | a conic gradient border turning around it (`--k-glow-1`, `--k-glow-2`) |
| Inactive windows (`body.k-dim`) | slightly darker |

A style picks its own: `--k-open: k-fade` for the debugger, `k-slide` for the photographer.

## Floating and tiling {#layouts}

- `float`: windows where the page or the user put them, dragged by the title bar, resized by the corner.
- `tile`: the first opened window takes 56 % on the left, the others share the right, with `--k-gap-in` / `--k-gap-out`
  around them; a maximized window zooms over the others. The windows glide to their place.
- `Kit.set_layout("tile")` switches live; the settings switch does the same.

## Scenes {#scenes}

`Kit.scene(name)` minimizes the open windows that the scene does not want, opens the ones it wants (`desktop` for the
desktop, `scenes.<name>` or the app of the same name otherwise), places the main one large and gives it the focus. The address
becomes `#scene-<name>`, so a reload comes back to it.
