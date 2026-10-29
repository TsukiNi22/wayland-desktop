+++
title = "Situations et fenêtres"
summary = "Les sept situations, les actions des fenêtres, le lanceur, le menu, les notifications et la mosaïque."
keywords = "situations touches fenêtres déplacer redimensionner agrandir réduire lanceur menu mosaïque notifications"
+++

Ce que tous les styles partagent : les situations, les fenêtres et les moyens d'y accéder.

## Situations {#scenes}

Une situation est un état du bureau. On change avec les touches ou la barre en bas à gauche ; l'adresse la garde
(`jpop.html#scene-browser`).

| Touche | Situation | Ce qui s'ouvre |
|---|---|---|
| <kbd>1</kbd> | Bureau | les widgets du style |
| <kbd>2</kbd> | Verrouillage | l'écran de verrouillage du style, n'importe quel mot de passe + <kbd>Entrée</kbd> |
| <kbd>3</kbd> | Fichiers | le gestionnaire de fichiers, en grand |
| <kbd>4</kbd> | Navigateur | le navigateur, en grand |
| <kbd>5</kbd> | Terminal | le terminal, en grand |
| <kbd>6</kbd> | Musique | le lecteur (+ les widgets du style) |
| <kbd>7</kbd> | Réglages | les réglages |

## Fenêtres {#windows}

| Action | Comment |
|---|---|
| Déplacer | glisser la barre de titre |
| Redimensionner | glisser le coin en bas à droite |
| Agrandir | double-clic sur la barre de titre, ou son bouton du milieu |
| Réduire / fermer | les boutons de la barre de titre |
| Rouvrir | le dock ou la liste des tâches |
| Focus | cliquer n'importe où dans la fenêtre |

## Lanceur et menu {#launcher}

- <kbd>Ctrl</kbd>+<kbd>Espace</kbd> : le lanceur ; tapez un nom, <kbd>Entrée</kbd> ouvre le premier résultat, <kbd>Échap</kbd> le ferme.
- Clic droit sur le bureau : le menu du style (ex : `MIKU MIKU BEAM!`), puis ouvrir terminal / fichiers / navigateur, fond suivant,
  réglages, verrouillage.

## Notifications {#notifications}

Elles s'affichent en haut à droite et partent après quelques secondes ; un clic en ferme une. **Ne pas déranger** dans les
réglages les masque.

## Mosaïque {#tiling}

L'interrupteur **Tiling layout (Hyprland-like)** des réglages change la disposition en direct : la première fenêtre prend la
partie gauche, les autres s'empilent à droite, avec des espaces. Agrandir zoome alors une fenêtre. Le style `tty` démarre en
mosaïque. Le fonctionnement : [animations et mosaïque](page:motion-and-tiling#layouts).
