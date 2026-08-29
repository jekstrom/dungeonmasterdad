# T004: Death unlocks blizzard and grants the can

**Story**: US-017  
**Status**: Todo  
**Depends on**: T003  
**Parallel**: no

## Goal

On boss death, unlock `bemidji_blizzard` and grant `pickups/bajablast/bajablast.png`.

## Files

- `_globals/DMUnlocks.gd` — add `bemidji_blizzard` (false at reset)
- `pickups/bajablast/bajablast.png` — exists (32×32, Dew silhouette)
- Pickup / unlock effect pattern: `pickups/effects/unlock_fireball.gd` (Code Red)
- `dm/dm_ability_catalog.gd` — catalog id for the spell (cast body is T005)

## Requirements

- FR-002, AC2, AC3
- Unlock is host-authored. Locked cast does nothing (T005 / US-014 `try_cast`).
- Grant the can as a DM item/pickup. Cozy wielding is US-020; cube is US-019 — this is the token only.
- Do not hard-gate unlock on dungeon exit (AC9).

## Acceptance

- **Given** the boss reaches 0 HP, **When** death resolves, **Then** `bemidji_blizzard` is unlocked and the Baja Blast can is granted or dropped.
- **Given** Blizzard is not unlocked, **When** the DM tries to cast it, **Then** nothing happens and mana is unchanged.

## Notes

Cast pocket + slow is T005. Do not implement fireball (US-018).
