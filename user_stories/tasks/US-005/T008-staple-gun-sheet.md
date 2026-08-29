# T008: Wire staple-gun player sheet

**Story**: US-005  
**Status**: Todo  
**Depends on**: T002  
**Parallel**: with T005

## Goal

Wire `player/sprites/player_staple_gun.png` for ranged idle/walk/shoot. Do **not** wait on a restyle. Do **not** stretch the sword into a pen.

## Files

- `player/sprites/player_staple_gun.png` — exists (1024×192, 64×64 cells; row 0 S then N, row 1 E then W, 8 frames per dir idle/walk/shoot)
- `player/sprites/player_pencil_melee.png` — melee sheet (T005)
- `player/sprites/PlayerSprite02.png` — current sword sheet; keep as fallback only, do not distort it into office weapons

## Requirements

- Required New Art Assets table in US-005
- Same 64×64 / 4-direction layout as the current player sheet.
- Ranged uses the staple-gun sheet; melee uses the pencil sheet. Switching weapons/actions switches sheets, not a stretched sword.
- Don't block T002 if animation timing is still rough; frames must still be the office-gun art.

## Acceptance

- **Given** the player is idle/walking/shooting the staple gun, **When** a peer looks at them, **Then** they see `player_staple_gun.png`, not a stretched sword.
- **Given** a melee swing, **When** a peer looks, **Then** they see `player_pencil_melee.png` plus the ink slash, not the sword sheet.

## Notes

Pen vs pencil is a cosmetic/skin, not two damage models. Do not author a second catalog of player bodies.
