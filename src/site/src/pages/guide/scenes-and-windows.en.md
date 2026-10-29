+++
title = "Scenes and windows"
summary = "The seven scenes, the window actions, the launcher, the menu, the notifications and the tiling layout."
section = "guide"
order = 2
keywords = "scenes keys windows drag resize maximize minimize launcher menu tiling notifications"
+++

What every style shares: the scenes, the windows and the ways to reach them.

## Scenes {#scenes}

A scene is a situation of the desktop. Switch with the keys or the bar at the bottom left; the address keeps it
(`jpop.html#scene-browser`).

| Key | Scene | What opens |
|---|---|---|
| <kbd>1</kbd> | Desktop | the widgets of the style |
| <kbd>2</kbd> | Lock | the lock screen of the style, any password + <kbd>Enter</kbd> unlocks |
| <kbd>3</kbd> | Files | the file manager, large |
| <kbd>4</kbd> | Browser | the browser, large |
| <kbd>5</kbd> | Terminal | the terminal, large |
| <kbd>6</kbd> | Music | the player (+ the widgets of the style) |
| <kbd>7</kbd> | Settings | the settings |

## Windows {#windows}

| Action | How |
|---|---|
| Move | drag the title bar |
| Resize | drag the bottom right corner |
| Maximize | double-click the title bar, or its middle button |
| Minimize / close | the buttons of the title bar |
| Reopen | the dock or the task list |
| Focus | click anywhere in the window |

## Launcher and menu {#launcher}

- <kbd>Ctrl</kbd>+<kbd>Space</kbd>: the launcher; type a name, <kbd>Enter</kbd> opens the first result, <kbd>Esc</kbd> closes it.
- Right-click the desktop: the menu of the style (ex: `MIKU MIKU BEAM!`), then open terminal / files / browser, next wallpaper,
  settings, lock screen.

## Notifications {#notifications}

They show at the top right and leave after a few seconds; a click closes one. **Do not disturb** in the settings hides them.

## Tiling {#tiling}

The settings switch **Tiling layout (Hyprland-like)** changes the layout live: the first window takes the left part, the
others stack on the right, with gaps. Maximize then zooms a window. The `tty` style starts tiled. How it works:
[motion and tiling](page:motion-and-tiling#layouts).
