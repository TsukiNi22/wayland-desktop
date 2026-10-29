+++
title = "Le synthé"
summary = "Comment les morceaux sont écrits, comment le kit les joue avec Web Audio et comment un style réagit au tempo."
keywords = "synthé musique morceaux web audio séquenceur tempo bpm gamme batterie"
+++

Aucun fichier audio : chaque morceau est quelques chaînes jouées en direct par Web Audio, et le tempo pilote les animations des styles.

## Morceaux {#tracks}

```js "Un morceau"
{
    title: "Negi Beam Polka", artist: "39 Channel", bpm: 152, wave: "square", gain: 0.09, vibrato: 4,
    scale: [60, 62, 64, 67, 69, 72, 74, 76, 79, 81, 84, 86, 88, 91, 93, 96],
    lead: "4.4.5.4.2.2.0.2.4.4.5.7.7-......",
    bass: "0.4.0.4.3.7.3.7.",
    drums: "k.s.k.s.k.s.k.ss",
}
```

| Champ | Sens |
|---|---|
| `scale` | 16 notes MIDI ; un chiffre `0`-`f` de `lead` / `bass` en choisit une |
| `lead`, `bass` | un caractère par double croche : un chiffre = une note, `.` = silence, `-` = tenir la note précédente |
| `drums` | `k` grosse caisse, `s` caisse claire, `h` charleston, `.` rien |
| `bpm`, `loops` | tempo, nombre de boucles avant le morceau suivant |
| `wave`, `gain`, `vibrato` | oscillateur de la mélodie, son niveau, profondeur du vibrato en Hz |

## Lecture {#playback}

Un tic par double croche programme les notes : oscillateurs avec une courte enveloppe (la basse une octave plus bas), un
passe-bas sur la mélodie, du bruit filtré pour la caisse claire et le charleston, une sinusoïde qui descend pour la grosse
caisse. Un analyseur alimente les barres du visualiseur et `Kit.level()`.

## Réagir à la musique {#react}

| Événement | Utilisé par |
|---|---|
| `step` | Miku chante une syllabe par note, les paroles / la tête de lecture de l'éditeur avancent, étincelles au refrain |
| `beat` | la cage d'Ado et le personnage Miku pulsent, les roses 3D prennent une rafale |
| `music` | lecture / pause : la silhouette d'Ado se met à se cambrer, les libellés « en cours » |

## Modifier un morceau en direct {#live}

Un morceau est un simple objet : l'éditeur vocal de Miku écrit sa grille directement dans `track.lead`, le tic suivant la joue.
