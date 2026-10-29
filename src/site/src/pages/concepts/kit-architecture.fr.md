+++
title = "Comment un style est construit"
summary = "Un kit, six habillages : ce que font kit.js / kit.css et ce qu'apporte une page de style."
keywords = "architecture kit page de style fenêtres applis init habillage"
+++

Chaque style est une page HTML posée sur le même kit : la page apporte son apparence et ses widgets, le kit fait le reste.

## Un kit, six habillages {#overview}

| Partie | Rôle |
|---|---|
| `kit/kit.css` | structure des fenêtres, applis, verrouillage et calques, toutes les couleurs en variables `--k-*` |
| `kit/kit.js` | gestionnaire de fenêtres, situations, verrouillage, lanceur, menu, notifications, les applis, le synthé |
| `<style>.html` | les valeurs `--k-*`, le décor (fond, personnage, scène), ses fenêtres, `Kit.init(...)` |

## Une page de style {#style-page}

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

Chaque clé de `Kit.init` est dans l'[API du kit](page:kit-api#options), chaque variable dans [Variables CSS](page:css-variables#all).

## Fenêtres écrites dans la page {#adopt}

Une `<section class="win">` dans le `.desk` devient une fenêtre : le kit enveloppe son contenu, ajoute la barre de titre
(`data-title`, `data-icon`) et le coin de redimensionnement, et la range par son `id`. Les ids de `desktop` s'ouvrent sur la
situation bureau ; un bouton `data-app="<id>"` l'ouvre, lui donne le focus ou la réduit ; les éléments `data-clock` affichent l'heure.

## Applis créées à la demande {#apps}

`files`, `browser`, `terminal`, `music`, `settings` et `viewer` sont construites à leur première ouverture, puis gardées (le
terminal garde son historique). `Kit.spawn("terminal")` crée une autre instance (`terminal-2`...).

## Réagir au kit {#events}

La page écoute le kit avec `Kit.on` : `beat` et `step` pour la musique, `scene`, `lock`, `accent`, `layout`...
Chaque événement et ses données : [API du kit](page:kit-api#events).
