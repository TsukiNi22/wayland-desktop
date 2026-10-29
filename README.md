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

> Hyprland (Lua config, 0.55+), waybar, wofi, kitty, hyprlock and mako configs inspired by the POCs, a GNOME-like overview
> (quickshell) and live wallpapers that follow the music, in `config/`

```bash
./install.sh                    # asks
./install.sh all                # every style + the switcher in the top bar
./install.sh tty                # one style alone: system, dev, ado, tty, miku, photographer
./install.sh --no-packages all  # the configs only
./install.sh remove             # remove the configs and put back the saved files (the packages stay)
```

`install.sh` first installs the packages of the chosen config for the distribution (sudo asked once, only when one is
missing), then the configs for the user; run through `sudo`, it installs the packages and gives the configs to `$SUDO_USER`
(what the `Wayland` setup of [dump](https://github.com/TsukiNi22/dump) does with the chosen mode).

| Family | Packages |
| ------ | -------- |
| fedora-like | `dnf`, copr `sdegler/hyprland` for Hyprland and hyprlock |
| debian-like | `apt` (Debian 13+, recent Ubuntu) |
| arch-like | `pacman` |

> [!NOTE]
> Every config: Hyprland, hyprlock, waybar, wofi, kitty, swaybg, mako, grim, slurp, wl-clipboard, brightnessctl, playerctl,
> wireplumber, libnotify, nautilus, btop, quickshell (overview, lock of better-tty and Dev), cava (music), python GTK +
> WebKit 4.1 + gtk-layer-shell (live wallpapers), Pillow (animated cursors), the Adwaita cursor and the fonts (JetBrains
> Mono, Font Awesome, Noto CJK, Noto Sans Symbols 2, Noto Color Emoji); each style adds the `PACKAGES` of its `style.env`
> (its font, `mpv` + `yt-dlp` + `mpv-mpris` for the radio of Ado and Miku, `espeak-ng` for the voice of the Miku beam). A package missing in the repositories of the family is skipped: the overview falls back to the wofi
> launcher, the wallpaper to the still image, the radio tells what it needs.

| Mode | Content |
| ---- | ------- |
| `all` | every style, the switcher module in the top bar (click: menu, scroll: next / previous), `wd-style` |
| `<style>` | only that style, no switcher |

| Keys | Effect |
| ---- | ------ |
| `Super` (alone) / `Super` again or `Super+A` | overview of the workspaces and their windows / applications grid (typing searches) |
| drag a window in the overview | to another workspace, or to the last empty one to create a workspace (GNOME: an emptied workspace goes away, the next ones move down) |
| `Super+Return` / `Super+Q` | terminal (kitty) |
| `Super+R` | launcher (wofi) |
| `Super+Shift+W` / `Super+Alt+W` | style menu / next style (`all` mode) |
| `Super+1` - `Super+0` | workspaces (key codes: azerty and qwerty), `+Shift`: move the window there |
| `Ctrl+Alt+arrows`, `Super+Page_Up/Down`, `Super+Alt+left/right` | previous / next workspace, `+Shift`: with the window |
| `Alt+Tab` / `Super+Tab` | next window / last workspace |
| `Super+S` / `Super+Shift+S` | scratchpad / move the window to it |
| `Super+L` / `Super+X` | lock / power menu |
| `Super+C` / `Super+F` / `Super+V` | close / fullscreen / floating |
| `Super+N` / `Super+Shift+N` | last notification again / dismiss them all |
| `Super+Shift+B` / `Super+Shift+C` | live / still wallpaper, animated / normal cursor (normal by default) |
| `Print` / `Shift+Print` | screenshot of a zone (clipboard) / of the screen (`~/Pictures`) |

| Style | Live wallpaper (`config/styles/<style>/wallpaper.html`) |
| ----- | ------------------------------------------------------ |
| System | aurora, a 3D sphere of points pushed by the music, perspective grid, waveform, light clock |
| Dev / low level | scrolling hex dump, 3D terrain of the last seconds of the spectrum, registers, phosphor CRT |
| Ado / blue rose | a backlit cage and its silhouette, WORLD DOMINATION and its globe of conquered cities, a fan chat with the rose-chan emotes, giant song titles, the blue rose, a vinyl radio to click |
| Terminal / better-tty | ASCII 3D torus in a tmux pane, rose-pine spectrum, block clock, neofetch pane, glyph rain, CRT |
| Miku | ring of spectrum around the 39, rising notes, twin-tail ribbons, the 39.39 FM radio to click, the sticky note of the POC (click it: MIKU MIKU BEAM) |
| Photographer | light leak, bokeh, film grain and dust, viewfinder |

| Lock (`Super+L`) | |
| ---------------- | - |
| Terminal / better-tty | a shell: fastfetch block (the image of your fastfetch, the stats of the PC), `> ` prompt: `login` (then the password), `switch <profile>` (Tab completes), `whoami`, `profiles`, `help`, `music`, `suspend` / `reboot` / `poweroff`, and `sudo`, `sl`, `cowsay`, `matrix`, `hack`... for fun |
| Dev / low level | a getty: the info of the lock, then `login:` and `Password:` |
| the others | hyprlock, the lock screen of the style (the password shows as emojis in Ado and Miku) |

> [!TIP]
> The radios of Ado and Miku play their `radio.json`: a few tracks are kept offline (千本桜, ワールドイズマイン, うっせぇわ,
> 新時代: downloaded once by `install.sh` with yt-dlp in `~/.local/share/wd-radio`, a personal copy, never in this
> repository) and start at once, the others are YouTube searches (mpv + yt-dlp). The title, the media keys and the bar
> follow (mpv-mpris); they keep playing across a change of style and stop with the live wallpaper. Your own emotes (png,
> gif, webp...) in `~/.local/share/wd-emotes` join the rose-chan ones in the Ado chat.

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
