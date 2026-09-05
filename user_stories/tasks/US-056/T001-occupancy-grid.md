# T001: Host occupancy grid

**Story**: US-056  
**Status**: Done  
**Depends on**: Dungeon walkable cells, MapBounds interior/cliffs, building placement  
**Owner**: Gameplay / Systems

## Goal

Host-authoritative per-cell occupancy: walkable vs blocked. Blocked = walls, cliffs, void, enabled building footprints (and doodads that already stop `CharacterBody2D`). Other units are **not** solids. Dirty when dungeon commits, interior commits, or a building places/destroys. Prefer region updates over full rebuild.

## Requirements

- FR-001, FR-002, FR-011, AC9, AC13

## Acceptance

- **Given** a generated dungeon, **When** occupancy is queried, **Then** hallway/room floor cells are walkable and wall cells are blocked.
- **Given** the exit door (floor tile not in `walkable_cells`) and overworld west of the dungeon, **When** occupancy is queried, **Then** the door and overworld interior are walkable; generation `blocked_cells` leftover is not a wall.
- **Given** overworld interior vs cliff ring, **When** queried, **Then** interior is walkable (minus solids) and cliff/void is blocked.
- **Given** an enabled factory, **When** occupancy updates, **Then** its footprint cells are blocked; on destroy they become walkable again if the ground is otherwise legal.
- **Given** two monsters on one cell, **When** occupancy is read, **Then** the cell stays walkable (units are not solids).
