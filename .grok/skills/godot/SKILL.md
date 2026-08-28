---
name: godot
description: >
  Godot 4.7 GDScript, scenes, and multiplayer rules for Dungeon Master Dad.
  Use when editing .gd/.tscn, spawners, synchronizers, autoloads, or the
  dungeon generator. Triggers: Godot, GDScript, MultiplayerSpawner, RPC,
  y-sort, DungeonGenerator, /godot.
when-to-use: GDScript, .tscn, MultiplayerSpawner, MultiplayerSynchronizer, autoload, y-sort
paths: ["**/*.gd", "**/*.tscn", "**/*.tres"]
metadata:
  short-description: Godot 4.7 and multiplayer conventions
  author: dungeon-master-dad
---

# Godot

Engine is **Godot 4.7** (Forward Plus). There is no `Node2D.y_sort_origin`.

Style, state machines, and RPC annotations: `AGENTS.md`. This skill is the engine/multiplayer procedure.

## Scripts and scenes

- Typed GDScript. `class_name` for types other scripts instantiate; otherwise `preload` if headless parse fails.
- Node refs: `@onready`. Missing nodes: `get_node_or_null`.
- Keep scene-tree changes in `_enter_tree` / `_ready` as the existing node already does. Do not add `_process` work that can be a signal.
- Parent `y_sort_enabled` flattens nested y-sort. Put wall/player/monster sprites as y-sorted children whose node origin is the south foot.

## Multiplayer

- World spawn authority is peer `1`. Call `Lobby.is_network_server()` before generating dungeons or treating `multiplayer.is_server()` as "the host clicked Start". `OfflineMultiplayerPeer` reports unique id 1 / `is_server() == true` before Start/Join.
- `MultiplayerSpawner` replicates **direct** children of `spawn_path` that match spawnable scenes. Do not `add_child` spawnable scenes under `spawn_path` on the client. Tiles go under `GeneratedTiles`, not the entity spawn path.
- `add_child(node, true)` for replicated names. Unique names for generated monsters (`spawn_id.validate_node_name()`).
- Player `set_multiplayer_authority(id)` is recursive. Do not put spawners or tile sync under the player. Keep `MultiplayerSpawner.set_multiplayer_authority(1)` on every peer in `_enter_tree`.
- Client join errors to treat as bugs: `_update_spawn_visibility` `ERR_BUG`, `on_spawn_receive` `has_node`, `on_delta_receive` invalid synchronizer.

## Dungeon generator

- Place `scenes/dungeon_generator.tscn`. Inspector knobs: start/exit, bounds, `room_size`, `room_count`, `request_id`, `generate_on_ready`, `generate_on_host_started`.
- Playground: `generate_on_ready = false` so a joining client does not build a second dungeon. Host Start emits `Lobby.host_started`.
- Generation API: `DungeonGenerationManager.request_generate_dungeon(payload)` (server). Payload fields in `scripts/procedural_dungeon/resources/dungeon_generation_request.gd`.
