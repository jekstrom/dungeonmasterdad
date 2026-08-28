# T006: Place the cliff ring

**Story**: US-024  
**Status**: Todo  
**Depends on**: T002, T004 (T003 for final art; T005 so dungeon origin is known)  
**Parallel**: after interior rect exists

## Goal

One-cell (or documented thickness) cliff ring around the interior: N/E/S/W edges and four outer corners. Host places them; they are the only non-walkable map border.

## Files

- `_globals/level_manager.gd` or map fill owner — iterate cliff cells, instance `level/cliff.tscn` with the correct frame
- Parent under a dedicated node (e.g. `GeneratedTiles` sibling `CliffTiles`) so dungeon tile replace RPCs do not wipe cliffs
- `scripts/procedural_dungeon/cliff_catalog.gd`

## Requirements

- FR-001, FR-009, FR-010
- Interior is the only walkable play area for both player types.
- Optional void tiles beyond the ring are never walkable.

## Acceptance

- **Given** a committed interior, **When** the ring is placed, **Then** every interior edge cell has a matching cliff neighbor outside the interior, plus four outer corners.
- **Given** a cliff cell, **When** catalog identity is checked, **Then** it is a cliff tile, not `level/wall.tscn` and not an outside grass/dirt tile.

## Notes

Host-only placement. Replication of the ring is T014 if not already covered by a spawner. Do not put cliffs on `MultiplayerSpawner` spawn_path if that would reintroduce `_update_spawn_visibility` ERR_BUG; follow the generated-tile RPC pattern in `scripts/multiplayer_spawner.gd`.
