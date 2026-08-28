# T014: Host-authoritative map replication and late join

**Story**: US-024  
**Status**: Done  
**Depends on**: T006, T011, T012  
**Parallel**: no

## Goal

Every peer, including a client who joins after fill, sees the same interior rectangle, cliff ring, dungeon origin, outside fill, and tree set.

## Files

- Host commit payload (bounds + cliff cells + outside cells + tree list) — extend generated-tile sync in `scripts/multiplayer_spawner.gd` or a dedicated map-sync RPC
- `_globals/dungeon_generation_manager.gd` — dungeon AABB already server-side; include origin in the map payload
- Client: do not locally generate cliffs/fill/trees on `OfflineMultiplayerPeer`; wait for host (`Lobby.is_network_server()`)

## Requirements

- FR-010, MR-001, MR-002, AC10
- Movement past the cliff is still rejected on the server (T007) even if the client is stale.

## Acceptance

- **Given** a late-joining client, **When** they receive the map, **Then** interior size, cliff ring, dungeon placement, outside fill, and tree set match the host.
- **Given** join, **When** the client log is read, **Then** there is no `_update_spawn_visibility` `ERR_BUG`, `on_spawn_receive` `has_node`, or invalid synchronizer from this map spawn path.

## Notes

Prefer the existing generated-tile replace RPC pattern over putting every cliff/outside tile on the playground `MultiplayerSpawner` spawn_path. Unique names per cell (`validate_node_name()`).
