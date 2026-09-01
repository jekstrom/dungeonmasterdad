# T001: Exit forest pocket from live exit

**Story**: US-032  
**Status**: Todo  
**Depends on**: US-015 exit cell/door, US-024 map bounds  
**Parallel**: no

## Goal

Define the **exit forest pocket**: outside cells immediately beyond the procedural dungeon exit (overworld landing side). Keep a clear **egress** (exit door cell + ≥1 adjacent outside landing cell). Never include dungeon footprint, cliffs, non-interior, or west PP spawn strip.

## Files

- `_globals/level_manager.gd` — `dungeon_exit_cell()`, map apply
- `scripts/procedural_dungeon/map_bounds.gd` — interior / dungeon AABB helpers
- `scripts/procedural_dungeon/tile_placement_builder.gd` — exit door pick (if door ≠ exit room center)
- `level/dungeon_exit.tscn` / exit groups — locate door world/cell
- Suggested: exit-forest planner helper next to tree scatter

## Requirements

- FR-002, FR-003, FR-005, AC2, AC4
- Pocket is derived from the **live** exit after generation commit.
- Eligible cells are **outside** only.
- Document / expose the mandatory clear egress set.

## Acceptance

- **Given** a committed exit, **When** the pocket is queried, **Then** every pocket cell is interior outside, not dungeon, not cliff, not west spawn strip.
- **Given** that pocket, **When** egress cells are listed, **Then** they include the exit door / landing path and are marked non-place for trees and Skill Tree.

## Notes

Prefer the west/overworld face of an east-flush dungeon (US-015 / US-024). Do not place doodads in this task.
