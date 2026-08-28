# T009: Paper Pusher spawn on the west interior edge

**Story**: US-024  
**Status**: Done  
**Depends on**: T004  
**Parallel**: with T010

## Goal

Paper Pushers spawn on the **left (west)** interior boundary, on outside tiles, not in the dungeon and not on cliff cells, with enough clear cells for the Reality spawn set (US-001).

## Files

- `scripts/multiplayer_spawner.gd` — `spawn_player`
- `_globals/player_manager.gd` — `get_respawn_position` (today Reality Zone center fallback)
- `zones/RealityZone.gd` — spawn point generation must sit on the west strip inside the interior
- Map bounds — **west spawn strip** entity (story Key Entities)

## Requirements

- FR-005, AC5
- Strip is outside tiles (T011); until US-023, spawn on empty interior cells that will become outside, never dungeon/cliff.
- Enough clear cells for the Reality spawn set (US-001).

## Acceptance

- **Given** match start, **When** a Paper Pusher spawns, **Then** their cell is on the west interior edge, interior-only, not a dungeon cell, not a cliff cell.
- **Given** respawn, **When** a spawn point is chosen, **Then** it is still on that strip (or a documented interior Reality cell), never past the cliffs.

## Notes

DM spawn is T010. Do not spawn Paper Pushers at world origin `(0,0)` unless that cell is the west strip.
