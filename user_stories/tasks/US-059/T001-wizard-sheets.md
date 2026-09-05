# T001: Generate DM wizard sheets

**Story**: US-059  
**Status**: Todo  
**Depends on**: —  
**Owner**: Art

## Goal

Produce the four identity-locked **512×384** sheets in US-059 Required New Art Assets.

**James-locked pipeline:** Do **NOT** prompt the image model for a full sprite sheet or multi-row grid. Generate **single frames** or **1-row strips** with **smooth/subtle** explicit pose deltas, on a **solid non-green** flat keyable background (prefer `#FF00FF`). Fit each cell to **128×128** (same foot baseline / scale). **Stitch** into the final 4×3 sheet with a **script** (PIL or equivalent). Keep one canonical down identity lock across every cell.

**James-locked animation style:** Quiet idle breath; no bounce. No **hand item-swaps** inside a state’s frames (staff stays staff on idle/walk/attack; d20 stays d20 on cast). **No green or near-green fringe** after keying (protects the green Dew can).

**James staged approval:** Get James’s **OK on the walk-down 1-row strip first** before any other facing (side/up) or state (idle/attack/cast). Do not batch the rest until that strip is approved.

## Walk-down strip (gate)

Before side/up walk or other sheets:

1. Produce a **1-row** walk-down strip (4 frames) from the canonical down lock.
2. Motion = **L/R feet only** (stride / leg contact-pass). Do **not** flip the whole body for the “other” step.
3. **Staff stays in the same hand** on all four frames.
4. **No color drift** — palette/hexes match the canonical lock.
5. Show James; only after approval, edit to side/up and build idle/attack/cast from the same lock.

## Files

- `dm/sprites/dm_idle.png`
- `dm/sprites/dm_walk.png`
- `dm/sprites/dm_attack.png`
- `dm/sprites/dm_cast.png`

Do not edit `dm/sprites/PlayerSprite02.png` into a wizard.

## Requirements

- Deliverable: 128×128 cells, 4×3 grid (512×384), rows down / side / up, 4 frames each — **assembled by stitch script**, not by prompting a grid.
- Side faces viewer’s right.
- Lock: red robe, brown pointed hat, green Dew can on the hip, same face/scale/palette/foot baseline.
- Idle + walk + attack: wooden staff in the dominant hand (no mid-clip prop morph).
- Cast: d20 in the dominant hand; Dew still on the hip (no mid-clip prop morph).
- Idle: **quiet breath** only — tiny chest/shoulder motion.
- Walk/attack/cast: **smooth/subtle** deltas between consecutive frames.
- Canonical down frame first; walk-down strip approved before expanding.
- Solid BG must not be green/near-green; keyed edges must not show green fringe.

## Acceptance

- **Given** the walk-down strip, **When** James reviews, **Then** it is approved before other facings/states are generated.
- **Given** walk-down frames, **When** compared, **Then** motion is L/R feet only, no body flip for opposite step, staff hand unchanged, colors match the lock.
- **Given** each final PNG, **When** opened, **Then** size is 512×384 and twelve 128×128 cells are packed with no gutters.
- **Given** generation logs / sources, **When** reviewed, **Then** prompts were single-frame or 1-row only (no full-sheet/grid prompt) and the sheet was script-stitched.
- **Given** idle frames, **When** flipped as a loop, **Then** motion reads as quiet breath (not a walk or bounce).
- **Given** any state’s four frames, **When** compared, **Then** the hand prop does not swap mid-clip.
- **Given** keyed silhouettes, **When** inspected, **Then** there is no green or near-green fringe.
- **Given** the four sheets side by side, **When** compared, **Then** they are the same wizard (robe, hat, Dew, proportions), not four different characters.
