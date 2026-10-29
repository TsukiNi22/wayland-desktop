# wayland-desktop

> [!TIP]
> Documentation [TsukiNi22/wayland-desktop](https://tsukini22.github.io/wayland-desktop/) (v0.1.0) and
> [live demo](https://tsukini22.github.io/wayland-desktop/poc/index.html).

Six interactive desktop styles in HTML / CSS / JS, built on one small kit, to compare the looks before writing the real
Wayland configuration. Every style has working windows, a lock screen, files, a browser, a terminal, music and settings.

### Table of Contents
 - [Themes](#themes)
 - [Lock screens](#lock-screens)
 - [Usage](#usage)
 - [Branches](#branches)
 - [Credits](#credits)

## Themes

| | | |
| ---- | ---- | ---- |
| <img src="docs/images/system-desktop.jpg" width="300"> | <img src="docs/images/dev-desktop.jpg" width="300"> | <img src="docs/images/jpop-desktop.jpg" width="300"> |
| [**System**](https://tsukini22.github.io/wayland-desktop/poc/system.html) | [**Dev / low level**](https://tsukini22.github.io/wayland-desktop/poc/dev.html) | [**Ado / blue rose**](https://tsukini22.github.io/wayland-desktop/poc/jpop.html) |
| Hyprland-like rice, live monitor, quick settings | playable debugger, registers, memory | Ado Box, Ado TV, 3D blue roses |
| | | |
| <img src="docs/images/tty-desktop.jpg" width="300"> | <img src="docs/images/miku-desktop.jpg" width="300"> | <img src="docs/images/photographer-desktop.jpg" width="300"> |
| [**Terminal / better-tty**](https://tsukini22.github.io/wayland-desktop/poc/tty.html) | [**Miku**](https://tsukini22.github.io/wayland-desktop/poc/miku.html) | [**Photographer**](https://tsukini22.github.io/wayland-desktop/poc/photographer.html) |
| tmux tiling with `Ctrl+b`, rose-pine | vocal editor she sings, MIKU MIKU BEAM | photo wall, lightbox, real histogram |

## Lock screens

| | | |
| ---- | ---- | ---- |
| <img src="docs/images/system-lock.jpg" width="300"> | <img src="docs/images/dev-lock.jpg" width="300"> | <img src="docs/images/jpop-lock.jpg" width="300"> |
| **System** | **Dev / low level** (BIOS prompt) | **Ado / blue rose** |
| | | |
| <img src="docs/images/tty-lock.jpg" width="300"> | <img src="docs/images/miku-lock.jpg" width="300"> | <img src="docs/images/photographer-lock.jpg" width="300"> |
| **Terminal / better-tty** (getty login) | **Miku** | **Photographer** (viewfinder) |

## Usage

```bash
git clone -b poc https://github.com/TsukiNi22/wayland-desktop.git
cd wayland-desktop
./serve.sh              # http://localhost:8039/index.html, opened in the browser
./serve.sh jpop.html    # open a given page
```

| Key / action | Effect |
| ------------ | ------ |
| `1` - `7` | scenes: desktop, lock, files, browser, terminal, music, settings |
| `Ctrl+Space` | launcher |
| right-click on the desktop | menu of the style |
| title bar: drag / double-click | move / maximize a window |

> [!NOTE]
> Opening `index.html` directly (`file://`) works too, except the YouTube videos of the Ado page: YouTube refuses its embedded
> player on `file://` pages, each video then opens on YouTube.

## Branches

| Branch | Content |
| ------ | ------- |
| `main` | this README and its screenshots (`docs/images/`) |
| `poc` | the POCs at the root: `kit/` (shared kit), one `*.html` per style, `assets/`, `vendor/` (three.js), `serve.sh` |
| `gh-pages` | the [documentation site](https://tsukini22.github.io/wayland-desktop/) and the [live demo](https://tsukini22.github.io/wayland-desktop/poc/index.html) (`poc/`) |

## Credits

> [!CAUTION]
> The MIT license of this repository covers the code only. The assets keep their own licenses (CC0, CC BY, CC BY-SA, and the
> non-commercial Crypton license for the Hatsune Miku art): see [`assets/CREDITS.md`](https://github.com/TsukiNi22/wayland-desktop/blob/poc/assets/CREDITS.md).
> The Ado page only links / embeds the official YouTube videos, nothing of them is stored here.
