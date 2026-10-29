+++
title = "How a style is built"
summary = "One kit, six skins: what kit.js / kit.css do and what a style page brings."
section = "concepts"
order = 1
keywords = "architecture kit style page adopt windows apps init skin"
+++

Every style is one HTML page on top of the same kit: the page brings its look and its own widgets, the kit does the rest.

## One kit, six skins {#overview}

| Part | Role |
|---|---|
| `kit/kit.css` | structure of the windows, apps, lock screen and overlays, all colors in `--k-*` variables |
| `kit/kit.js` | window manager, scenes, lock screen, launcher, menu, notifications, the apps, the synth |
| `<style>.html` | the `--k-*` values, the decor (wallpaper, character, stage), its own windows, `Kit.init(...)` |

## A style page {#style-page}

```html "my-style.html"
<link rel="stylesheet" href="kit/kit.css">
<style>:root { --k-accent: #ff4fa3; --k-radius: 18px; }</style>
<div class="desk">
    <section class="win" id="clock" data-title="Clock" data-icon="⏰" style="left: 40px; top: 60px; width: 260px">
        <div data-clock="hms"></div>
    </section>
    <nav class="dock"><button data-app="clock">⏰</button><button data-app="terminal">⌨️</button></nav>
</div>
<script src="kit/kit.js"></script>
<script>Kit.init({name: "My style", desktop: ["clock"]});</script>
```

Every key of `Kit.init` is in the [Kit API](page:kit-api#options), every variable in [CSS variables](page:css-variables#all).

## Windows written in the page {#adopt}

A `<section class="win">` in the `.desk` becomes a window: the kit wraps its content, adds the title bar (`data-title`,
`data-icon`) and the resize corner, and lists it by its `id`. The ids of `desktop` open on the desktop scene; a button with
`data-app="<id>"` opens, focuses or minimizes it; `data-clock` elements show the time.

## Apps created on demand {#apps}

`files`, `browser`, `terminal`, `music`, `settings` and `viewer` are built the first time they open, then kept (the
terminal keeps its history). `Kit.spawn("terminal")` makes another instance (`terminal-2`...).

## Reacting to the kit {#events}

The page listens to the kit with `Kit.on`: `beat` and `step` for the music, `scene`, `lock`, `accent`, `layout`...
Every event and its data: [Kit API](page:kit-api#events).
