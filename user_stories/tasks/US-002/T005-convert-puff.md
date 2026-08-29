# T005: Optional convert puff

**Story**: US-002  
**Status**: Todo  
**Depends on**: T003  
**Parallel**: no

## Goal

If Neutral→Reality (or Fantasy→Reality) is too subtle, play a short grey paper/dust puff on convert. Do **not** block T003 on this.

## Files

- `sprites/reality_drift_puff.png` — exists (6×32 frames)
- Small VFX instance on the converting cell (match `pickups/metal` / fireball-scale VFX, not a 128 floor)

## Requirements

- Required New Art Assets table in US-002
- Optional: ship T003 without puff if the swap already reads; required if the swap is too subtle in play.
- Puff is cosmetic; missing puff must not fail conversion.

## Acceptance

- **Given** a tile converts and puff is enabled, **When** the swap happens, **Then** `reality_drift_puff.png` plays on that cell and does not change collision.
- **Given** puff assets or playback fail, **When** T003 fires, **Then** the tile still converts.

## Notes

Do not invent a second tile catalog. Do not use dungeon floor frames as the puff.
