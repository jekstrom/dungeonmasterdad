# T005: Convert puff

**Story**: US-004  
**Status**: Todo  
**Depends on**: T003  
**Parallel**: no

## Goal

Play a short sparkle/blood fleck puff on convert. Do **not** block T003 on this.

## Files

- `sprites/fantasy_drift_puff.png` — exists (6×32 frames)
- Small VFX instance on the converting cell (match fireball-scale VFX / sparkle language like `sprites/sparks.png`, not a 128 floor)

## Requirements

- Required New Art Assets table in US-004
- Puff is cosmetic; missing puff must not fail conversion.
- Do not block T003 if the puff is not wired yet.

## Acceptance

- **Given** a tile converts and puff is enabled, **When** the swap happens, **Then** `fantasy_drift_puff.png` plays on that cell and does not change collision.
- **Given** puff assets or playback fail, **When** T003 fires, **Then** the tile still converts.

## Notes

Do not invent a second tile catalog. Do not use dungeon floor frames as the puff. Do not reuse `sprites/sparks.png` as the strip (28×4, too small).
