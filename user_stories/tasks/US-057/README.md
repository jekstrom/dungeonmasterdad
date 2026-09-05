# US-057 tasks: Generalized maze-shaped dungeon layouts

**Story**: [US-057.md](../../US-057.md)  
**Branch**: `057-maze-shaped-dungeons`  
**Status**: Done  

Replace L-backbone + L-hallway generation with compact, maze-like layouts; freer entrance/exit. Host-only. US-015/024 portal and east-flush AABB stay.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-layout-metrics-and-knobs.md) | Compactness / winding metrics + optional braid / auto-portal knobs | Gameplay | Existing request payload | |
| [T002](T002-scatter-rooms.md) | Scatter start/exit/mid rooms in bounds (no L-backbone requirement) | Gameplay | T001 | |
| [T003](T003-maze-corridors.md) | Maze-inspired 4-connected hallway carve + braid loops | Gameplay | T002 | |
| [T004](T004-freer-portals.md) | Freer entrance/exit placement; auto-place sentinel; overworld door still legal | Gameplay | T002 | with T003 |
| [T005](T005-infill-footprint.md) | Use leftover bounds for maze infill so the footprint is not a sausage of rooms | Gameplay | T003 | |
| [T006](T006-verification-harness.md) | Square compact AABB, winding path, free portals, connectivity, content planners | QA / Gameplay | T003–T005 | |

## Independent test

Square bounds, several seeds: compact walkable AABB, winding start→exit, branches/loops, entrance/exit not glued to opposite poles. PathValidator still connects. East-flush commit unchanged.
