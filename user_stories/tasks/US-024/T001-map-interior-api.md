# T001: Map interior and cliff ring API

**Story**: US-024  
**Status**: Todo  
**Depends on**: none  
**Parallel**: can run with T003

## Goal

Give the match a single axis-aligned **map interior** in tile cells and a **cliff ring** around it. Other tasks query this instead of inventing local rectangles.

## Files

- `scripts/procedural_dungeon/map_bounds.gd` (new) — `Rect2i` interior, cliff cells, helpers: `is_interior_cell`, `is_cliff_cell`, `is_world_position_in_interior`, clamp-to-interior.
- `_globals/level_manager.gd` and/or a small map-bounds owner on the playground — hold the live match bounds.
- `scripts/procedural_dungeon/dungeon_grid.gd` — reuse 128×128 cell conversion (`from_world` / `to_world`).
- `_globals/signal_bus.gd` — emit when bounds are committed (host).

## Requirements

- FR-001, FR-010
- Cell size 128×128 world units (story assumption).
- +X is east (right), west is left.

## Acceptance

- **Given** committed interior `Rect2i`, **When** a world position is tested, **Then** interior vs cliff vs outside-the-ring is unambiguous.
- **Given** no match bounds yet, **When** generation has not committed, **Then** callers get an empty/invalid rect and must not treat the void as walkable.

## Notes

Do not place tiles or collision here. Dungeon AABB and 4× sizing are T004. `DungeonGenerationManager.is_world_position_in_dungeon` stays dungeon-only; interior is a larger rect that contains the dungeon.
