# Alex's photographic taste

**Read this before curating any "best photos" selection.** It is the closest
thing to a trained model here — a rubric plus a growing exemplar set, corrected
by Alex when it gets things wrong. Update it every time he pushes back.

`photofind taste` prints this file.

---

## He shoots on four cameras and they are not equal

| Camera | Filename | Mode |
|---|---|---|
| **Leica Q3** | `L100xxxx.DNG/.JPG` | The deliberate work. Architecture, geometry, considered frames. **Weight heaviest.** |
| **Ricoh GR III Monochrome** | `<epoch>_R000xxxx.JPG` | Street, B&W, high contrast. Deliberate. |
| **Fuji X100VI** | `DSCFxxxx.JPG` | Walk-around; between deliberate and casual. |
| **iPhone** | `IMG_xxxx.HEIC` | Family documentation. Volume lives here; the best work usually does not. |

**The camera is the single strongest signal of intent.** He picked up a real
camera because he meant to make a photograph. When ranking, a Leica or Ricoh
frame should clear a much lower bar than an iPhone frame to make a cut.

⚠️ ~2,775 of 4,068 previewable frames in a recent 3-month window were iPhone.
Rank naively and the deliberate work is buried by sheer volume of snapshots.

## What he actually rates (his words, 2026-07-28)

He pushed back on a first pass with: *"There are some really good architectural
/ artsier photos from Montreal that I'm surprised you didn't include."* The five
he sent as exemplars:

1. **Bonaventure métro** — long exposure, train streaking through frame, a
   purple/yellow graphic poster lit above it, deep black surround.
2. **Houndstooth balcony tower** — hard sun glinting off staggered balconies,
   cerulean sky, wispy cirrus, strong diagonal.
3. **Green fins on blue glass** — repeating chartreuse louvres, receding
   perspective, two-thirds empty sky.
4. **Under the Champlain bridge** — dead-centre one-point perspective, piers
   marching to a vanishing point, Montreal skyline on the horizon, B&W.
5. **Brothers in the cargo box** — Leica B&W, one boy kissing the other's helmet,
   shallow depth, city softened behind. *The one human frame, and it works for
   the same reasons: geometry, restraint, patience.*

### The throughline

- **Geometry over sentiment.** Repetition, grids, diagonals, vanishing points.
- **Negative space is the subject.** Big empty sky, big empty water, big black.
- **Looking up or looking through.** Extreme angles; rarely eye level.
- **Restrained colour, or committed colour.** Either near-monochrome with one
  accent (chartreuse, purple), or full graphic saturation. Never muddy.
- **Light doing structural work** — a sun glint, a streaking train, fog.
- **People are small, or absent.** When a person is in frame they are an
  element, not the point.
- **Patience is visible.** These are frames he waited for.

### What he does NOT rate as "best"

Tight centred close-ups of the kids. There are thousands and they are precious,
but they are documentation, not photographs. **Apple's aesthetic score loves
exactly these** and will fill a top-20 with them if left alone.

## Favorites — a real signal, deliberately under-weighted

Alex's own caveat: *"not a perfect signal, I don't always get to go through and
favorite."* True — but it is far from noise, and it **independently confirms the
camera hypothesis**:

| Camera | Shot (3 mo) | Favorite rate |
|---|---|---|
| **Ricoh GR III Mono** | 556 | **19.1%** |
| **Leica Q3** | 932 | **17.2%** |
| iPhone | 4,173 | 11.6% |
| Fuji X100VI | 243 | 0.4% *(a batch he never triaged)* |

All-time: 13,420 of 127,670 favorited (10.5%).

He stars his deliberate-camera frames at ~1.6× the rate of phone frames, without
being asked to and without knowing anyone would count. That is a cleaner read on
intent than anything Apple computes.

By contrast, favorites barely track Apple's aesthetic score — mean 0.515 for
favorited vs 0.469 for everything. **Apple's model is not predicting what he
values.**

**Use favorites as a tiebreaker and a calibration check, never as a filter.**
A 12% favorite rate means ~88% of the good stuff is unstarred. The Fuji row is
the proof: 0.4% is not a verdict on the X100VI, it is a batch he never got to.
`best` adds a small bonus for a star and marks favorited tiles with `*`.
`--favorites-only` restricts to them when that is explicitly wanted.

## Feedback loop — how to actually refine this

Contact-sheet tiles are **numbered** (and starred if favorited). Alex gives
feedback by number: *"12 and 31 are the good ones, 4 is boring, why did you skip
19?"* Numbers resolve through `<outdir>/index.json` → uuid, date, camera,
filename.

When he corrects a selection:
1. Pull the frames he named and look at them again *against* what was picked.
2. Write the principle that would have caught it into **What he actually rates**.
3. Add a dated line to the correction log — including his verbatim words.
4. If the miss was mechanical (a bug, a filter, a missing directory), fix the
   code AND log it. Taste failures and plumbing failures look identical from
   the outside.

## Method

1. Pull a candidate pool with `photofind best`, but **stratify by camera** — take
   the top N of Leica / Ricoh / Fuji explicitly before filling with iPhone.
2. Build contact sheets. **Look at all of them.**
3. Select against the throughline above, not against Apple's ranking.
4. Aim for range: architecture, street, portrait, landscape, macro, one or two
   genuine human moments. Twenty variations on one idea is not a portfolio.
5. Say which one is the weakest and why. He'd rather hear it.

## Correction log

- **2026-07-28 (later)** — Alex: *"can you number the photos so I can easily give
  you feedback"* + asked whether favorites were visible. Added numbered tiles,
  `*` markers on favorited frames, `--favorites-only`, and the favorite-rate
  breakdown above. Numbering is now on by default for every sheet.
- **2026-07-28** — First pass returned 20 near-identical iPhone close-ups of the
  kids. Two causes: (a) a **bug** — `preview_path()` only globbed
  `derivatives/<char>/` and missed `derivatives/masters/<char>/`, where every
  RAW-import preview lives, silently excluding **1,221 of 1,221 Leica frames**;
  (b) trusting Apple's face-biased ranking. Fixed the glob, added camera
  stratification, wrote this file. Alex's verdict on v1: *"I don't know that I
  totally agree with your taste but it's not bad."*
