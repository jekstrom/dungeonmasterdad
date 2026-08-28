# T005: Commit dungeon flush to the east interior edge

**Story**: US-024  
**Status**: Done  
**Depends on**: T004  
**Parallel**: no

## Goal

The generated dungeon sits against the **right (east)** interior edge, fully inside the interior, not centered in the map, and not overlapping cliff cells.

## Files

- `_globals/dungeon_generation_manager.gd` — world origin / cell translation at commit
- `scripts/procedural_dungeon/dungeon_generator.gd` — start/exit/bounds chosen so the AABB can sit east (or generate in local cells then translate)
- `scripts/multiplayer_spawner.gd` — `_place_dm_at_entrance` already uses `get_entrance_world_position()`; that position must land in the east dungeon
- `playground.tscn` — stop using a centered/free-floating generator pose as the match layout

## Requirements

- FR-004
- Vertically centered in the interior, or flush north if interior height equals dungeon height (FR-002).
- Dungeon cells MUST NOT replace cliff cells.
- Exit faces the overworld (west of the east-edge dungeon), not the cliff (US-015 adjacency; exit neighbor cells are reserved in T012).

## Acceptance

- **Given** dungeon commit, **When** the dungeon AABB is compared to the interior, **Then** `aabb.end.x == interior.end.x` (flush east in cell space) and `aabb` is fully inside the interior.
- **Given** cliff cells, **When** dungeon tiles are placed, **Then** no dungeon floor/wall occupies a cliff cell.

## Notes

Do not change room/hallway generation. Translate or choose `bounds_origin` so the committed AABB is east. Paper Pusher spawn is T009.
