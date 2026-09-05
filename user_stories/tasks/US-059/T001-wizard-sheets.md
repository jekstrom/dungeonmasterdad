# T001: Generate DM wizard sheets

**Story**: US-059  
**Status**: Todo  
**Depends on**: —  
**Owner**: Art

## Goal

Produce the four identity-locked **512×384** sheets in US-059 Required New Art Assets.

**James-locked pipeline:** Do **NOT** prompt the image model for a full sprite sheet or multi-row grid. Generate **single frames** or **1-row strips** with **explicit pose deltas** between steps, on a **solid / flat keyable background**. Fit each cell to **128×128** (same foot baseline / scale). **Stitch** into the final 4×3 sheet with a **script** (PIL or equivalent). Keep one canonical down identity lock across every cell.

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
- Idle + walk + attack: wooden staff in the dominant hand.
- Cast: d20 in the dominant hand; Dew still on the hip.
- Canonical down frame first; every other cell is an edit (or 1-row strip harvest) from that lock with pose-only deltas.

## Acceptance

- **Given** each PNG, **When** opened, **Then** size is 512×384 and twelve 128×128 cells are packed with no gutters.
- **Given** generation logs / sources, **When** reviewed, **Then** prompts were single-frame or 1-row only (no full-sheet/grid prompt) and the sheet was script-stitched.
- **Given** the four sheets side by side, **When** compared, **Then** they are the same wizard (robe, hat, Dew, proportions), not four different characters.
