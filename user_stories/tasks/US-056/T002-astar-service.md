# T002: Shared A* path service

**Story**: US-056  
**Status**: Done  
**Depends on**: T001  
**Owner**: Gameplay / Systems

## Goal

One host `AStarGrid2D` (or equivalent) on the occupancy grid. **4-connected** A\*. API: request path from start cell to goal cell. Skip A\* when a walkable 4-connected line exists. Repath interval **0.4s** unless goal cell changes or the path is invalid. Cap **8** searches per frame; queue the rest. Optional **512** expansion cap with partial path. Optional `(start, goal)` cache TTL **0.25s**, flushed on occupancy dirty. Generation `PathValidator` MUST NOT be the runtime loop.

## Requirements

- FR-001, FR-002, FR-008, FR-009, FR-010, FR-012, FR-014, AC7, AC8, AC10, AC11, AC14

## Acceptance

- **Given** start and goal with a wall between them and a hallway around, **When** the service paths, **Then** the result is a 4-connected walkable cell list around the wall, never through it.
- **Given** a clear 4-connected line, **When** requested, **Then** A\* does not run (LOS skip).
- **Given** 20 requests in one frame, **When** the budget is 8, **Then** at most 8 searches run; the others queue.
- **Given** no walkable route, **When** requested, **Then** the result is empty / failure — not a path through solids.
- **Given** an unchanged goal cell and a still-valid path, **When** called before the repath interval, **Then** it returns/follows the existing path without a new search.
