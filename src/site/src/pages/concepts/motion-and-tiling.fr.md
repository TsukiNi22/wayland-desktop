+++
title = "Animations et mosaïque"
summary = "Les animations façon Hyprland, les dispositions libre et en mosaïque, et comment une situation ouvre ses fenêtres."
keywords = "animation hyprland popin dépassement mosaïque disposition espaces situation espace de travail bordure assombrir"
+++

Les animations reprennent celles des configurations Hyprland ; les dispositions et les situations sont quelques fonctions du kit.

## Animations façon Hyprland {#motion}

| Effet | Comment |
|---|---|
| Une fenêtre s'ouvre | grandit depuis 80 % avec la courbe à dépassement `cubic-bezier(0.05, 0.9, 0.1, 1.05)` (`--k-open`, `--k-ease`) |
| Une fenêtre se ferme / se réduit | rétrécit / tombe et s'efface en 0,2 s avant de disparaître |
| La situation change | les fenêtres glissent comme un changement d'espace de travail |
| Fenêtre active (`body.k-glow`) | une bordure en dégradé conique qui tourne autour (`--k-glow-1`, `--k-glow-2`) |
| Fenêtres inactives (`body.k-dim`) | légèrement assombries |

Chaque style choisit les siennes : `--k-open: k-fade` pour le débogueur, `k-slide` pour le photographe.

## Libre et mosaïque {#layouts}

- `float` : les fenêtres là où la page ou l'utilisateur les a mises, déplacées par la barre de titre, redimensionnées par le coin.
- `tile` : la première fenêtre ouverte prend 56 % à gauche, les autres se partagent la droite, avec `--k-gap-in` / `--k-gap-out`
  autour ; une fenêtre agrandie zoome par-dessus les autres. Les fenêtres glissent jusqu'à leur place.
- `Kit.set_layout("tile")` change en direct ; l'interrupteur des réglages fait pareil.

## Situations {#scenes}

`Kit.scene(name)` réduit les fenêtres ouvertes que la situation ne veut pas, ouvre celles qu'elle veut (`desktop` pour le
bureau, `scenes.<name>` ou l'appli du même nom sinon), place la principale en grand et lui donne le focus. L'adresse devient
`#scene-<name>`, un rechargement y revient.
