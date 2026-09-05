# T004: Freer entrance and exit

**Story**: US-057  
**Status**: Todo  
**Depends on**: T002  
**Owner**: Gameplay  
**Parallel**: with T003

## Goal

Entrance and exit are **not** glued to opposite poles of the bounds.

- Explicit in-bounds start/exit still honored if rooms fit (separation, min cells).
- Sentinel / `auto_place_portals`: pick two legal room centers in the footprint (prefer perimeter cells that can face **overworld** for the exit door).
- Exit MUST still resolve to a door with outside landing (US-015, US-024 east-flush AABB). Entrance remains DM spawn (US-015).
- `EntranceExitResolver` relaxes “must be these exact cells as the only feasible pair” without allowing start == exit or out of bounds.

## Files

- `scripts/procedural_dungeon/entrance_exit_resolver.gd`
- `scripts/procedural_dungeon/tile_placement_builder.gd` (door pick)
- `scripts/procedural_dungeon/dungeon_generator.gd`

## Requirements

- FR-005, FR-008, FR-010, AC3, AC7

## Acceptance

- **Given** start and exit both in the interior of square bounds (not on opposite edges), **When** generate runs, **Then** it can succeed.
- **Given** auto-place, **When** generate runs, **Then** entrance ≠ exit, both in rooms, PathValidator connects, exit still lands on overworld.
