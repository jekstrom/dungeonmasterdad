# T003: Maze-inspired hallways

**Story**: US-057  
**Status**: Todo  
**Depends on**: T002  
**Owner**: Gameplay

## Goal

Replace default `HallwayCarver` L-carves with **maze-like 4-connected** corridors.

Inspiration: Growing Tree or recursive backtracker on a corridor lattice (e.g. odd/even cells, or carve through uncarved floor candidates), spanning rooms first so every room is reachable, then **braid** extra connections.

- 4-connected only (N/E/S/W). No diagonal corner-cut through walls.
- Shortest start→exit path MUST wind (T001 metric).
- L-carve MAY be fallback if maze carve cannot connect two rooms after N tries.

## Files

- `scripts/procedural_dungeon/hallway_carver.gd` (replace or wrap)
- Suggested: `scripts/procedural_dungeon/maze_corridor_carver.gd`
- `scripts/procedural_dungeon/maze_infill_generator.gd` (do not double-count with T005)

## Requirements

- FR-003, FR-004, FR-011, AC4, AC5

## Acceptance

- **Given** two rooms that are not axis-aligned on a short L, **When** hallways carve, **Then** the connection jogs / branches rather than a single elbow as the typical case.
- **Given** braid_rate > 0, **When** the maze is finished, **Then** at least some layouts have two distinct start→exit routes (imperfect maze).
