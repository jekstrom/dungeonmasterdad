# T010: DM spawns at the east dungeon entrance

**Story**: US-024  
**Status**: Todo  
**Depends on**: T005  
**Parallel**: with T009

## Goal

At match start the Dungeon Master appears at the dungeon entrance inside the right-edge dungeon (US-015), after that dungeon is committed on the east interior.

## Files

- `scripts/multiplayer_spawner.gd` — `spawn_host_player`, `_place_dm_at_entrance`, `get_entrance_world_position`
- `_globals/dungeon_generation_manager.gd` — `get_entrance_world_position`

## Requirements

- FR-004 (placement) + AC6
- Entrance world position is inside the east dungeon AABB and inside the interior.

## Acceptance

- **Given** the DM at match start, **When** they spawn, **Then** they are at the generated entrance, in the east-edge dungeon, not on the west strip and not on a cliff.

## Notes

Do not implement the full US-015 crawl/exit lock here. Only spawn position relative to this map layout. Keep `Lobby.is_network_server()` gating so clients do not generate a second dungeon.
