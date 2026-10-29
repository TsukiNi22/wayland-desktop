# wayland-desktop

> [!TIP]
> Documentation [TsukiNi22/wayland-desktop](https://tsukini22.github.io/wayland-desktop/) (v0.1.0) and
> [live demo](https://tsukini22.github.io/wayland-desktop/poc/index.html).

Six interactive desktop styles in HTML / CSS / JS, built on one small kit, to compare the looks before writing the real
Wayland configuration. Every style has working windows, a lock screen, files, a browser, a terminal, music and settings.

### Table of Contents
 - [Themes](#themes)
 - [Lock screens](#lock-screens)
 - [Wayland configs](#wayland-configs)
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

## Wayland configs

> Hyprland (Lua config, 0.55+), waybar, wofi, kitty and hyprlock configs inspired by the POCs, in `config/`

```bash
./install.sh            # asks
./install.sh all        # every style + the switcher in the top bar
./install.sh tty        # one style alone: system, dev, ado, tty, miku, photographer
./install.sh remove     # remove the configs and put back the saved files
```

| Mode | Content |
| ---- | ------- |
| `all` | every style, the switcher module in the top bar (click: menu, scroll: next / previous), `wd-style` |
| `<style>` | only that style, no switcher |

| Keys | Effect |
| ---- | ------ |
| `Super+Return` / `Super+Q` | terminal (kitty) |
| `Super+R` | launcher (wofi) |
| `Super+Shift+W` / `Super+Alt+W` | style menu / next style (`all` mode) |
| `Super+1` - `Super+0` | workspaces (key codes: azerty and qwerty) |
| `Super+L` | lock (hyprlock, the lock screen of the style) |
| `Super+C` / `Super+F` / `Super+V` | close / fullscreen / floating |
| `Print` / `Shift+Print` | screenshot of a zone (clipboard) / of the screen (`~/Pictures`) |

> [!NOTE]
> The packages (`hyprland`, `hyprlock`, `waybar`, `wofi`, `kitty`, `swaybg`, `mako`, `grim`, `slurp`, `wl-clipboard`...) are
> installed by the `Wayland` setup of [dump](https://github.com/TsukiNi22/dump), which also runs `install.sh` with the chosen
> mode (Fedora: copr `sdegler/hyprland`; Debian / Ubuntu and Arch: their repositories).

> [!IMPORTANT]
> The files already there are saved once (`<file>.wd-backup`) and put back by `./install.sh remove`;
> `~/.config/hypr/user.lua` (keyboard detected at the install) is yours and never replaced.

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
| `main` | the Wayland configs (`config/`, `install.sh`), this README and its screenshots (`docs/images/`) |
| `poc` | the POCs at the root: `kit/` (shared kit), one `*.html` per style, `assets/`, `vendor/` (three.js), `serve.sh` |
| `gh-pages` | the [documentation site](https://tsukini22.github.io/wayland-desktop/) and the [live demo](https://tsukini22.github.io/wayland-desktop/poc/index.html) (`poc/`) |

## Credits

> [!CAUTION]
> The MIT license of this repository covers the code only (the wallpapers of `config/styles/` reuse the POC images,
> same licenses, see [`config/CREDITS.md`](config/CREDITS.md)). The assets keep their own licenses (CC0, CC BY, CC BY-SA, and the
> non-commercial Crypton license for the Hatsune Miku art): see [`assets/CREDITS.md`](https://github.com/TsukiNi22/wayland-desktop/blob/poc/assets/CREDITS.md).
> The Ado page only links / embeds the official YouTube videos, nothing of them is stored here.
