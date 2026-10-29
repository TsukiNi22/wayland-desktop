+++
title = "Premiers pas"
summary = "Ouvrir les POC en ligne ou en local, et les premières choses à essayer."
keywords = "lancer ouvrir démo serve.sh file http installation"
+++

Où ouvrir les POC, comment les lancer en local et quoi essayer en premier.

## Démo en ligne {#demo}

Toutes les pages sont publiées sur GitHub Pages : [https://tsukini22.github.io/wayland-desktop/poc/](https://tsukini22.github.io/wayland-desktop/poc/index.html). Tout y marche, y compris les vidéos
YouTube de la page Ado.

## Ouvrir en local {#local}

```bash "Terminal"
git clone -b poc https://github.com/TsukiNi22/wayland-desktop.git
cd wayland-desktop
./serve.sh              # http://localhost:8039/index.html, ouvert dans le navigateur
./serve.sh jpop.html    # ouvre une page donnée
```

| Façon | Ce qui marche |
|---|---|
| Ouvrir `index.html` directement (`file://`) | tout, sauf les vidéos YouTube lues dans la page Ado |
| `./serve.sh` (`http://localhost:8039`) | tout |

> [!NOTE]
> YouTube refuse son lecteur intégré sur les pages `file://` : chaque vidéo d'Ado TV s'ouvre alors sur YouTube.

## Premiers pas {#first-steps}

1. Ouvrez un style depuis l'accueil, en plein écran avec <kbd>F11</kbd>.
2. Appuyez sur <kbd>1</kbd> à <kbd>7</kbd> pour parcourir les [situations](page:scenes-and-windows#scenes).
3. Déplacez une fenêtre par sa barre de titre, double-cliquez la barre pour l'agrandir.
4. <kbd>Ctrl</kbd>+<kbd>Espace</kbd> ouvre le lanceur, un clic droit sur le bureau ouvre le menu.
5. Ouvrez la musique (<kbd>6</kbd>) et lancez la lecture : chaque style réagit au tempo.

Ensuite : [situations et fenêtres](page:scenes-and-windows#scenes).
