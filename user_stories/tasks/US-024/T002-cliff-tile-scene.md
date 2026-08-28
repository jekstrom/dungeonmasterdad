# T002: Cliff tile scene, collision, and catalog

**Story**: US-024  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T003 (wire frames when art lands)

## Goal

A cliff cell is a catalog tile, not a dungeon wall and not outside grass. Players collide with it. South-foot y-sort matches floors/walls.

## Files

- `level/cliff.tscn` (new) — 128×128 cell, sprite offset `(0, -63)` like `level/wall.tscn` / `level/floor.tscn`.
- `level/cliff.gd` (new) — edge/corner frame enum (N, E, S, W, NW, NE, SW, SE), optional void.
- `scripts/procedural_dungeon/cliff_catalog.gd` (new) — approved cliff scene path(s); do **not** list `level/wall.tscn`.
- Collision: StaticBody2D (or equivalent) on physics layer used by players; mask so Paper Pushers and DM both stop.

## Requirements

- FR-009
- South cliff has a **face** so approaching from the south y-sorts in front of the lip; from the north the lip overlaps the sprite (same feel as dungeon walls).
- Collision matches the visible lip, not the full 128×128 if the art is a drop-off (south face especially).

## Acceptance

- **Given** a cliff cell, **When** a Paper Pusher or DM walks into it, **Then** they stop on the last interior cell.
- **Given** the catalog, **When** inspected, **Then** cliff scenes are distinct from `level/wall.tscn` and outside tiles.
- **Given** missing final art, **When** the scene is placed, **Then** a labeled placeholder frame is allowed until T003.

## Notes

Do not reuse `sprites/cubicle_stone_wall.png` as the world border. Host places cliffs in T006; this task only makes the placeable tile.
