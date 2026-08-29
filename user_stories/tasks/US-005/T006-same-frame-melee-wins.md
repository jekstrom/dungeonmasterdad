# T006: Same-frame melee wins

**Story**: US-005  
**Status**: Todo  
**Depends on**: T002, T005  
**Parallel**: no

## Goal

If melee and fire are pressed on the **same frame**, melee wins. Do **not** spend a staple for the unfired shot.

## Files

- `player/player.gd` input / state machine (fire + melee in one tick)

## Requirements

- Edge: melee and fire on the same frame
- Deterministic: melee interrupts the unfired shot.
- Magazine unchanged when melee wins.

## Acceptance

- **Given** melee and primary fire on the same frame and the magazine has ammo, **When** the host resolves input, **Then** melee plays, no staple projectile is created, and the magazine does not decrease.

## Notes

Do not invent a buffer window beyond the same physics/input frame unless one already exists for other actions.
