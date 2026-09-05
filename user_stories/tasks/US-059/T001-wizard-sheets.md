# T001: Generate DM wizard sheets

**Story**: US-059  
**Status**: Todo  
**Depends on**: —  
**Owner**: Art

## Goal

Produce the four identity-locked sheets in US-059 Required New Art Assets using `/create-sprite-animation`.

## Files

- `dm/sprites/dm_idle.png`
- `dm/sprites/dm_walk.png`
- `dm/sprites/dm_attack.png`
- `dm/sprites/dm_cast.png`

Do not edit `dm/sprites/PlayerSprite02.png` into a wizard.

## Requirements

- 128×128 cells, 4×3 grid (512×384), rows down / side / up, 4 frames each.
- Side faces viewer’s right.
- Lock: red robe, brown pointed hat, green Dew can on the hip, same face/scale/palette/foot baseline.
- Idle + walk + attack: wooden staff in the dominant hand.
- Cast: d20 in the dominant hand; Dew still on the hip.
- Canonical down frame first; every other cell is an edit/video harvest from that lock.

## Acceptance

- **Given** each PNG, **When** opened, **Then** size is 512×384 and twelve 128×128 cells are packed with no gutters.
- **Given** the four sheets side by side, **When** compared, **Then** they are the same wizard (robe, hat, Dew, proportions), not four different characters.
