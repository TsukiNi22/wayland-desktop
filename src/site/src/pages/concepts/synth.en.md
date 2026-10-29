+++
title = "The synth"
summary = "How the tracks are written, how the kit plays them with Web Audio and how a style reacts to the beat."
section = "concepts"
order = 3
keywords = "synth music tracks web audio step sequencer beat bpm scale drums"
+++

No audio file: every track is a few strings played live by Web Audio, and the beat drives the animations of the styles.

## Tracks {#tracks}

```js "A track"
{
    title: "Negi Beam Polka", artist: "39 Channel", bpm: 152, wave: "square", gain: 0.09, vibrato: 4,
    scale: [60, 62, 64, 67, 69, 72, 74, 76, 79, 81, 84, 86, 88, 91, 93, 96],
    lead: "4.4.5.4.2.2.0.2.4.4.5.7.7-......",
    bass: "0.4.0.4.3.7.3.7.",
    drums: "k.s.k.s.k.s.k.ss",
}
```

| Field | Meaning |
|---|---|
| `scale` | 16 MIDI notes; a digit `0`-`f` of `lead` / `bass` picks one |
| `lead`, `bass` | one character per 16th note: a digit = a note, `.` = rest, `-` = hold the previous note |
| `drums` | `k` kick, `s` snare, `h` hi-hat, `.` nothing |
| `bpm`, `loops` | tempo, number of loops before the next track |
| `wave`, `gain`, `vibrato` | oscillator of the lead, its level, vibrato depth in Hz |

## Playback {#playback}

One tick per 16th note schedules the notes: oscillators with a short envelope (the bass one octave lower), a low-pass on the
lead, filtered noise for the snare and the hi-hat, a falling sine for the kick. An analyser feeds the visualizer bars and
`Kit.level()`.

## Reacting to the music {#react}

| Event | Used by |
|---|---|
| `step` | Miku sings a syllable per note, the lyrics / editor playhead move, sparks on the chorus |
| `beat` | the Ado box and the Miku character pulse, the 3D roses get a gust |
| `music` | play / pause: the Ado silhouette starts bending, the now playing labels |

## Editing a track live {#live}

A track is a plain object: the Miku vocal editor writes its grid straight into `track.lead`, the next tick plays it.
