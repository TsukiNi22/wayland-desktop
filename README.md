# Wayland desktop - POC

Interactive proofs of concept of desktop styles, built with HTML / CSS / JS before writing the real Wayland configuration.

## Table of Contents

- [Usage](#usage)
- [Styles](#styles)
- [Everywhere](#everywhere)
- [Layout](#layout)
- [Credits](#credits)

## Usage

Open `index.html` in a browser (full screen with `F11`), or serve the pages locally:

```bash
./serve.sh              # http://localhost:8039/index.html
./serve.sh jpop.html    # open a given page
```

> [!NOTE]
> The YouTube videos of the Ado page only play inside the page when it is served over http (`serve.sh`):
> YouTube refuses embeds on `file://` pages, each video then opens on YouTube.

## Styles

| Page | Style | Own interactions |
|---|---|---|
| `system.html` | System, Hyprland-like rice | pill bar, workspaces, live system monitor, quick settings (dark / light, night light, tiling, brightness) |
| `dev.html` | Dev / low level | playable debugger (step, continue, breakpoints, registers, flags, memory, stack), BIOS lock screen |
| `jpop.html` | Ado / blue rose | Ado Box stage (backlit cage, silhouette singing), Ado TV (official videos, lives, streams), 3D blue roses, うっせぇわ stamp, wishes |
| `tty.html` | Terminal / better-tty | tmux tiling with `Ctrl+b` keys, getty lock screen, w3m browser, git / cmake / nvim commands |
| `miku.html` | Miku | official KEI art, vocal editor she sings, hold-to-charge beam |
| `photographer.html` | Photographer | photo wall, lightbox, slideshow, real histogram, viewfinder lock screen |

## Everywhere

- Scenes: keys `1`-`7` or the bar at the bottom left (desktop, lock, files, browser, terminal, music, settings),
  also reachable with `#scene-<name>` in the URL.
- Windows: drag, resize, maximize, minimize, close, dock / task list, launcher (`Ctrl+Space`), right-click menu.
- Apps: files (fake file system shared with the terminal), browser (tabs, history, search), terminal (`help`),
  music (live synth, the styles react to the beat), settings (accent, wallpaper, tiling, animations, volume).
- Motion inspired by Hyprland and Waybar / Quickshell rices: popin windows, workspace slide, animated gradient
  border, dimmed inactive windows, tiling with gaps.

## Layout

| Path | Content |
|---|---|
| `kit/kit.js`, `kit/kit.css` | shared kit: window manager, scenes, lock screen, apps, synth |
| `*.html` | one page per style, `index.html` lists them |
| `assets/` | images and the 3D rose model, see `assets/CREDITS.md` |
| `vendor/` | three.js r147 (MIT) |
| `serve.sh` | local http server |

## Credits

> [!IMPORTANT]
> The MIT license of this repository covers the code only. The assets keep their own licenses (CC0, CC BY,
> CC BY-SA, and the non-commercial Crypton license for the Hatsune Miku art): see `assets/CREDITS.md`.
> The Ado page only links / embeds the official YouTube videos, nothing of them is stored here.
