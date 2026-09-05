---
name: create-sprite-animation
description: >
  Generate engine-ready 128x128 character sprite sheets for Dungeon Master Dad:
  one sheet per animation state, 3 facings (down, side, up) times 4 frames = 12
  cells. Side faces right; the game flips it for left. Use when creating walk,
  idle, attack, stun, or death sprites, sprite sheets, animation frames, or
  when the user runs /create-sprite-animation.
when-to-use: >
  sprite sheet, sprite animation, walk cycle, attack frames, 128x128 sprites,
  character animation, generate goblin/player/DM/monster art
argument-hint: [subject] [idle|walk|attack|stun|die] [more states...]
metadata:
  short-description: 128px 3-dir 4-frame sprite sheets
  author: dungeon-master-dad
---

# Create sprite animation (128px, 3-dir, 4-frame)

Read `game-asset-core`, `game-character-consistency`, `imagine`, and
`game-animation-frames` before generating. This skill owns the sheet
contract below; those skills own prompting, identity, and motion. The
4-frame count here wins over game-animation-frames' flexible count.

Godot clip wiring is `/setup-godot-2d-sprite-animation`. Do not invent a
left-facing row.

## Contract

| Item | Value |
|---|---|
| Cell | **128×128 px**, RGBA PNG |
| Facings | **down**, **side**, **up** only |
| Side | subject faces **viewer's right**; engine `scale.x = -1` for left |
| Frames / facing | **4** |
| Cells / state | **12** |
| Sheet / state | **4 columns × 3 rows** = **512×384 px** |
| Origin | south foot (y-sort). Feet land on the same baseline in every cell |
| Background | flat keyable color, no ground, no drop shadow, no scene |
| Camera | 3/4 top-down oblique, orthographic, locked |

Row order (Godot `hframes = 4`, `vframes = 3`):

```
row 0 down:  frames 0 1 2 3
row 1 side:  frames 4 5 6 7
row 2 up:    frames 8 9 10 11
```

One PNG per state: `{subject}_{state}.png` (e.g. `goblin_walk.png`).
Multiple states for one subject stay separate files unless the user asks
for a stacked atlas.

Clip names the sheet must support: `{state}_down`, `{state}_side`,
`{state}_up`.

## Lock card (write once, reuse verbatim)

Before any image call, write a lock card and keep it in every prompt:

1. **Identity** — species, body, outfit, hair, held item and which hand.
2. **Palette** — 4–8 hex colors sampled from the canonical frame. Repeat
   them every call.
3. **Scale** — subject height in-cell (target **88–110 px**). Feet on a
   baseline near the bottom of the cell with a few px of padding. Same
   silhouette width across facings.
4. **Style sentence** — one style/medium line (e.g. "stylized 2D game
   sprite, crisp cel shading, 3/4 top-down"). Keep it identical.
5. **Background hex** — one flat color (prefer `#00FF00` or `#FF00FF`).
6. **Asymmetry table** — viewer-relative: which side has the marker
   (sword, patch, bag) in down / side / up. Side is a true right-facing
   profile.

Do not `image_gen` the same character twice. Canonical frame first;
everything else is `image_edit` or video from that frame.

## Pipeline

Do this **per state**. Parallelize only within a numbered step.

### 1. Canonical down pose

`image_gen` **one** standing down-facing frame, `aspect_ratio` `1:1`.
Full lock-card words. Neutral pose for idle/walk; attack-ready for
attack. Isolated subject, flat background.

If the user attached a reference, `image_edit` from that instead.

Verify: 3/4 down (face and chest toward camera), feet planted, item
gripped, no crop, no shadow. Retry once if identity or scale is wrong.

This image is the identity lock. Sample its palette (PIL) and freeze
those hexes on the lock card.

### 2. Facing bases (side, up)

From the canonical down frame, `image_edit` twice:

- **Side:** strict right-facing profile. Nose, chest, toes point at the
  right edge. Same scale, palette, background, outfit. Viewer-relative
  asymmetry from the lock table.
- **Up:** back of head / shoulders toward camera, 3/4 from behind. Same
  lock. Do not draw a second face on the back of the head.

Keep style words in every edit. Verify each facing against the
asymmetry table and the canonical silhouette height.

### 3. Motion — four frames per facing

For **each** facing base, produce exactly four frames.

**Default (cycles: idle, walk, stun-loop):** `image_to_video` from that
facing's base. One motion, in place, camera locked, 6s. Prompt the
action only ("walks in place, side view, camera locked"). Harvest with
ffmpeg (`fps=12`), then pick **4** frames that:

- cover the cycle's distinct phases
- loop (frame 4 → frame 1)
- keep the subject registered (no slide)

Walk phases: contact → down/pass → opposite contact → pass. Idle:
tiny breath, not a walk. Attack (oneshot): anticipation → strike →
contact → recover. Death: hit → buckle → fall → downed.

**Fallback** if video drifts identity or camera: `image_edit` the facing
base into the next pose, three times, describing only the pose change
plus the lock card.

`image_edit` each chosen frame to restore flat background, palette hexes,
and cel style **without changing pose**.

### 4. Fit every frame to 128×128

Do not trust the generator's pixel size. For each of the 12 frames,
crop/pad in code so:

- output is exactly **128×128**
- feet sit on the **same baseline y** (measure from the canonical frame)
- horizontal center of the body matches the canonical frame
- transparent or the lock-card key color fills empty pixels
- nothing clipped (weapon, ears, hat)

A single PIL pass: detect the subject bbox, scale so height is 88–110 px
(same scale factor for all 12), then paste onto a 128×128 canvas at the
locked foot point.

### 5. Composite the sheet

4×3, no gutters, no divider lines, no labels:

```
[d0][d1][d2][d3]
[s0][s1][s2][s3]
[u0][u1][u2][u3]
```

Save `{subject}_{state}.png` at **512×384**. Confirm with PIL:
`size == (512, 384)` and each cell is 128×128.

### 6. Verify the set

Read the sheet (and cells if needed). Blind-describe, then diff:

- 12 cells, three facings, four poses each
- same character, palette, height, foot baseline
- side faces right in every side cell
- down shows face; up shows back
- motion loops (or oneshot reads) when played 0→1→2→3
- no leftover video background, no baked shadow, no left-facing row

Fail any one cell → targeted `image_edit` of that cell only, then
re-composite. Do not regenerate the whole set.

## Motion cheat sheet

| State | Loop | Four frames |
|---|---|---|
| idle | yes | rest, inhale, rest, exhale (tiny) |
| walk | yes | L contact, L pass, R contact, R pass |
| attack | no | wind-up, strike, connect, recover |
| stun | yes | hit, wobble A, wobble B, hit |
| die | no | hit, buckle, fall, downed |

## Done when

- One 512×384 PNG per requested state, 128×128 cells, rows down/side/up.
- Identity, palette, scale, and foot baseline hold across all 12 cells.
- Side is right-facing only.
- Path and clip names (`{state}_down|_side|_up`) are reported to the user.
