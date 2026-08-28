---
name: testing
description: >
  How to test Dungeon Master Dad: headless Godot, procedural-dungeon contract
  tests, and host+client join. Use when verifying a change, writing a test,
  or the user asks to test, QA, or reproduce a client join bug. Triggers:
  test, headless, test_harness, client join, ERR_BUG, /testing.
when-to-use: verify, QA, headless Godot, host and client, spawn visibility
metadata:
  short-description: Headless and multiplayer verification
  author: dungeon-master-dad
---

# Testing

`godot` on PATH is 4.7.x. Project root: the repo root (directory with `project.godot`).

Do not claim a gameplay or multiplayer change works until a command below has been run, or say what you could not run.

## Procedural dungeon (no network)

These scripts call `DungeonGenerationManager.generate_dungeon_contract` and print pass/fail:

```bash
godot --path . --headless --quit-after 20 test_harness/procedural_dungeon/room_knobs_test.tscn
```

`us1_connectivity_test.gd`, `us2_layout_variety_test.gd`, and `us3_content_compliance_test.gd` are Node scripts. Run them as a `.tscn` with that script on the root (see `room_knobs_test.tscn`), not as a bare `.gd` main scene.

A `--script` extending `SceneTree` can call `generate_dungeon_contract` after one `process_frame` (autoloads are up; playground is not loaded unless you `change_scene_to_file`).

## Host + client

1. Confirm `DungeonGenerator.generate_on_ready` is false on playground so both editor instances do not generate on `OfflineMultiplayerPeer`.
2. Host: Start in one instance (or `Lobby.start_host` / `./start_server.sh` depending on the scene).
3. Client: Join in a second instance (`./start_client.sh` or the lobby Join button).
4. On the **client** log, count these as failures if they appear on join:

- `_update_spawn_visibility` / `ERR_BUG`
- `on_spawn_receive` / `has_node`
- `on_delta_receive` / invalid synchronizer

Headless pair: `simple_server.sh` + `simple_client.sh`, or `test_harness/run_tests.sh quick`. Those use `test_harness/*_test_scene.tscn`, not playground.

## After a code change

| Change | Minimum check |
|---|---|
| Generator knobs / layout | `room_knobs_test.tscn` plus dump line `role=mid` counts |
| Spawner, authority, tiles, monsters | host+client join, client log clean |
| Player movement / walls | play playground, north and south approach |
| RPC / death / pickups | host+client, then the affected action |

New tests belong under `test_harness/procedural_dungeon/` as a Node + `.tscn` that `quit`s on success.