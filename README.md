# photofind

Query Apple Photos from the terminal. Read-only, no dependencies beyond the
standard library plus `sips` (built into macOS) and `montage` (ImageMagick,
optional, for contact sheets).

Built 2026-07-28 while hunting for photos of the kids riding in the Bunch Bike.
It found them. The lessons from that hunt are baked in below — read the
**Landmines** section before trusting any result.

```sh
photofind doctor                    # what this library can and can't answer
photofind people                    # named people, by face count
photofind labels dog                # Apple's scene labels matching "dog"
photofind search -p Zephyr -l bicycle --since 2024-02-01
photofind sheet  -p Zephyr --since 2024-02 -o /tmp/hunt   # contact sheets
photofind export A1B2C3D4 -o ~/Desktop
photofind reveal A1B2C3D4           # open in Photos.app for full-res export
```

## Install — run once per machine

```sh
~/Code/tools/photo-find/install.sh
```

`~/Code/` syncs via Syncthing so the script travels between the Mini and the
MacBook, but **two things do not sync and must be done on each Mac**: the
`~/.local/bin` symlink, and macOS **Full Disk Access** (granted per-machine,
per-binary — Terminal.app and iTerm are separate entries). `install.sh` creates
the symlink, checks ImageMagick, probes the database, and prints the exact
Full Disk Access steps if the read fails.

Point at a non-default library with `--library` or `$PHOTOFIND_LIBRARY`.

## What it reads

| File | Holds |
|---|---|
| `database/Photos.sqlite` | assets, dates, GPS, favorites, faces, people, albums |
| `database/search/psi.sqlite` | Apple's on-device ML scene labels + search index |
| `resources/derivatives/` | ~1024px previews (present even when originals aren't) |
| `originals/` | full-resolution files (often nearly empty — see below) |

Opened `?immutable=1` so a running Photos.app can't cause lock contention and
nothing can be written back.

## Commands

**`doctor`** — asset counts, newest asset, how many originals vs previews are
local, whether ImageMagick is present, and warnings about iCloud optimization
and sync lag. Run this first when something looks wrong.

**`search`** — filters combine with AND:
`--label/-l` (repeatable, OR'd together) · `--person/-p` (repeatable, substring
match, OR'd) · `--all-people` (require every named person in the same photo) ·
`--text/-t` (indexed/OCR text) · `--since` / `--until` · `--favorite` ·
`--include-videos` · `--limit` · `--format text|json|uuid` · `--out` to export.

**`sheet`** — same filters, but tiles the results into contact sheets. This is
the workhorse. Apple's labels are too coarse to trust blind, so the reliable
loop is: cast a wide net → build sheets → look → pull the winners by tile index
from `index.json`.

**`best`** — rank a date range by Apple's aesthetic scores. `--sheet` builds
contact sheets of the top pool. **Read the warning below before trusting it.**

**`export`** — by UUID (prefixes accepted). **`reveal`** — spotlight an asset in
Photos.app so a human can export at full resolution. **`labels`**, **`people`** —
vocabulary discovery; run these before guessing filter values.

**`--explain`** — per-filter and cumulative counts. Use it the moment a result
is empty or smaller than expected.

## Landmines

Every one of these cost real time on the first run.

**1. `psi.sqlite` strings are NUL-terminated.** `content_string` comes back as
`'Bicycle\x00'`. `WHERE content_string = 'Bicycle'` matches **nothing**, silently.
Always `rstrip('\x00')`. `LIKE 'Bicycle%'` works and hides the problem, which is
worse — you get partial results and no error.

**2. Asset UUIDs are two little-endian int64s.**
`str(uuid.UUID(bytes=struct.pack("<qq", uuid_0, uuid_1))).upper()` joins
`psi.assets` to `ZASSET.ZUUID`. Big-endian (`>qq`) produces plausible-looking
UUIDs that match zero rows.

**3. An iCloud-optimized library has almost no originals on disk.** This one is
334 originals against 127,669 stills. Everything must fall back to
`resources/derivatives/` (~1024px). Fine for triage and for Facebook Marketplace;
not fine when full resolution is the point — use `reveal` and export by hand.

**4. Apple's scene labels are COARSE and will mislead you.** `cart` means
*shopping cart*. `stroller` fires on any wheeled kid-carrier including a cargo
bike. `bicycle` fires on every bike in the library. A front-loader cargo trike
gets tagged `stroller`, `cart`, `bicycle`, and sometimes `rickshaw` — no single
label is right. **Never report label matches as answers. Build a sheet and look.**

**5. `montage` breaks on spaces in paths.** "Photos Library.photoslibrary"
splits at the space, producing `no decode delegate for ... /Users/alex/Pictures/Photos`.
Copy sources to a space-free staging dir first — `sheet` already does this.

**6. The library lags iCloud.** Photos taken minutes ago are not searchable
until the Mac syncs them. `doctor` warns when the newest asset is over two hours
old. A photo you *know* exists but can't find may simply not be here yet.

**7. Pets are people.** Dogs show up in `ZPERSON` with face counts and are
filterable with `-p`. Their detection is much spottier than humans' — a dog can
be plainly visible and still not matched.

**8. An empty result is often a fact, not a bug.** `-p Zephyr -p Bender
--all-people --since 2024-02-01` returns zero. That is *correct*: 475 photos
contain both, but the newest is 2023-10-31. `--explain` shows `475 alone, 0
cumulative` and settles it in one command. Run it before debugging anything.

## On Apple's aesthetic scores

`ZASSET` carries `ZOVERALLAESTHETICSCORE`, `ZCURATIONSCORE`, `ZICONICSCORE`, and
`ZCOMPUTEDASSETATTRIBUTES` adds ~20 more axes: composition, lighting, sharp
focus, interesting subject, well-timed shot, harmonious colour, noise, clutter,
failure. All roughly -1..1. `best` blends them.

**Apple's model has a preference, not taste.** It is close to a face detector
with a bokeh bonus: a tight, centred, well-lit close-up ranks near the top
almost regardless of whether the photograph is interesting. Rank a family
library by raw `ZOVERALLAESTHETICSCORE` and you get 200 near-identical toddler
close-ups. It systematically under-rates landscapes, architecture, graphic
compositions, and anything where the subject is small in frame — exactly the
frames a person would call their best.

`best` re-weights toward interesting-subject and well-timed-shot and penalises
clutter and failure, which helps. It does not fix it. **Treat `best` as a
candidate ranker: pull a pool of ~240, sheet it, and choose by eye.**

## The pattern that works

Apple's labels get you a *candidate pool*, not an answer. Narrow structurally
(person, date, favorite), then triage visually:

```sh
photofind sheet -p Zephyr -l bicycle -l cart -l stroller -l wagon \
  --since 2024-02-01 --until 2026-07-01 -o /tmp/hunt
# look at /tmp/hunt/sheet_*.jpg, note the tile numbers you want
# map tile -> uuid via /tmp/hunt/index.json, then:
photofind export <uuid> <uuid> -o ~/Desktop/picks
```

Widen labels aggressively — false positives are cheap to skip on a contact
sheet, false negatives are invisible and expensive.

## Not implemented

Albums and memories are readable (`ZGENERICALBUM`, `ZMEMORY`) but unexposed.
Moments/places clustering, burst stacks, and edit history are untouched. Nothing
writes to the library, by design — creating albums would mean AppleScript or the
PhotoKit API, which is a different tool.

## Taste

`photofind taste` prints `taste.md` — Alex's curation rubric: which cameras
signal intent, what he actually rates, and a correction log. **Read it before
selecting anyone's "best" photos.** It is the closest thing to training here —
a rubric plus exemplars, corrected when it gets things wrong, not a model.

`best` stratifies its pool by camera because iPhone volume (2,775 of 4,068 in a
recent 3-month window) otherwise buries the deliberate Leica/Ricoh/Fuji work
entirely. `--no-stratify` disables it.
