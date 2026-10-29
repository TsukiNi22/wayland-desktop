+++
title = "Getting started"
summary = "Open the POCs online or locally, and the first things to try."
section = "guide"
order = 1
keywords = "start run open demo serve.sh file http install"
+++

Where to open the POCs, how to run them locally and what to try first.

## Online demo {#demo}

Every page is published on GitHub Pages: [https://tsukini22.github.io/wayland-desktop/poc/](https://tsukini22.github.io/wayland-desktop/poc/index.html). Everything works there, the YouTube videos of the
Ado page included.

## Open locally {#local}

```bash "Terminal"
git clone -b poc https://github.com/TsukiNi22/wayland-desktop.git
cd wayland-desktop
./serve.sh              # http://localhost:8039/index.html, opened in the browser
./serve.sh jpop.html    # opens a given page
```

| Way | What works |
|---|---|
| Open `index.html` directly (`file://`) | everything, except the YouTube videos playing inside the Ado page |
| `./serve.sh` (`http://localhost:8039`) | everything |

> [!NOTE]
> YouTube refuses its embedded player on `file://` pages: on them each video of Ado TV opens on YouTube instead.

## First steps {#first-steps}

1. Open a style from the home page, full screen with <kbd>F11</kbd>.
2. Press <kbd>1</kbd> to <kbd>7</kbd> to go through the [scenes](page:scenes-and-windows#scenes).
3. Drag a window by its title bar, double-click the bar to maximize it.
4. Press <kbd>Ctrl</kbd>+<kbd>Space</kbd> for the launcher, right-click the desktop for the menu.
5. Open the music (<kbd>6</kbd>) and press play: every style reacts to the beat.

Next: [scenes and windows](page:scenes-and-windows#scenes).
