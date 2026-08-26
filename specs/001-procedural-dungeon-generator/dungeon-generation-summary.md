# Dungeon Generation Feature Summary

## Feature

**Parameterized Procedural Dungeon Generation** on branch `001-procedural-dungeon-generator`.

The generator accepts a start position and exit position, creates a room/hallway dungeon layout, validates a traversable route, and uses existing project tile + monster content.

## How It Works (Runtime Flow)

1. **Request received (server-authoritative)**
   - Caller sends a generation payload with:
     - `requestId`
     - `startPosition` (`x`, `y`)
     - `exitPosition` (`x`, `y`)
     - `generationBounds` (`origin`, `size`)
   - Entry points:
     - RPC path: `request_generate_dungeon(...)`
     - Direct contract helper: `generate_dungeon_contract(...)`

2. **Validation and authority checks**
   - Ensures server execution.
   - Ensures request format is valid.
   - Ensures start/exit are different and inside bounds.

3. **Layout generation pipeline**
   - Resolves entrance/exit positions.
   - Builds room backbone around start and exit.
   - Carves a main hallway between them.
   - Adds maze-like infill branches for variety.
   - Composes walkable space and classifies room/hallway regions.
   - Validates that entrance and exit are connected by a traversable path.
   - Retries generation (bounded attempts) if required constraints fail.

4. **Content mapping and spawn planning**
   - Walkable and blocked cells are mapped to tile placements using approved tile catalog paths only.
   - Monster spawns are planned from approved monster catalog paths only.
   - Spawn planner excludes entrance and exit cells.

5. **World commit and rollback safety**
   - Builds `generated_dungeon_container.tscn` with tile instances.
   - Replaces current generated dungeon container in world via `LevelManager`.
   - Clears previous generated monsters and spawns new generated monsters through multiplayer spawner integration.
   - On any failure during commit/spawn, performs rollback cleanup.

6. **Contract response and signals**
   - Success returns payload with:
     - entrance/exit
     - room/hallway regions
     - main path
     - tile placements
     - monster spawns
   - Failure returns structured error code/message.
   - Emits `SignalBus` dungeon generation lifecycle signals.

7. **Telemetry**
   - Tracks total requests/successes/failures and failure-code counts.
   - Logs elapsed generation timing for success/failure.

## What Was Implemented

### 1) Server-authoritative generation flow
- Added autoload manager: `_globals/dungeon_generation_manager.gd`
- Requests are handled server-side through:
  - `request_generate_dungeon(...)`
  - `generate_dungeon_contract(...)`
  - `request_dungeon_layout(...)`
  - `get_dungeon_contract(...)`
- Authority and request validation are enforced before world commit.

### 2) Core generation modules
- `scripts/procedural_dungeon/entrance_exit_resolver.gd`
- `scripts/procedural_dungeon/room_graph_generator.gd`
- `scripts/procedural_dungeon/hallway_carver.gd`
- `scripts/procedural_dungeon/maze_infill_generator.gd`
- `scripts/procedural_dungeon/path_validator.gd`
- `scripts/procedural_dungeon/layout_composer.gd`
- `scripts/procedural_dungeon/room_region_classifier.gd`
- `scripts/procedural_dungeon/hallway_region_classifier.gd`

### 3) Existing content integration (tiles + monsters)
- Tile catalog: `scripts/procedural_dungeon/tile_catalog.gd`
- Monster catalog: `scripts/procedural_dungeon/monster_catalog.gd`
- Scene builder: `scripts/procedural_dungeon/dungeon_scene_builder.gd`
- Spawn planner: `scripts/procedural_dungeon/monster_spawn_planner.gd`
- Multiplayer spawner integration: `scripts/multiplayer_spawner.gd` via `spawn_monster_from_scene_path(...)`

### 4) Runtime commit/rollback behavior
- Generated scene container: `scenes/generated_dungeon_container.tscn`
- World swap hooks in `LevelManager`:
  - `replace_generated_dungeon_container(...)`
  - `clear_generated_dungeon_container()`
- Generation manager commit path:
  - builds tile scene container
  - clears prior generated monsters
  - spawns generated monsters
  - rolls back container + generated monsters on failure

### 5) Data models and contract output
- `scripts/procedural_dungeon/resources/dungeon_generation_request.gd`
- `scripts/procedural_dungeon/resources/dungeon_layout_data.gd`
- `scripts/procedural_dungeon/resources/dungeon_spawn_set.gd`
- Contract payload includes:
  - entrance/exit
  - room/hallway regions
  - main path
  - tile placements
  - monster spawns

### 6) Telemetry and docs
- Added generation telemetry in `_globals/dungeon_generation_manager.gd`:
  - request/success/failure counters
  - failure-code aggregation
  - elapsed timing logs for success/failure
- Added runtime/debug workflow documentation in `README.md`
- Updated quickstart validation evidence in `specs/001-procedural-dungeon-generator/quickstart.md`

## How To Use It

### A) Generate a dungeon from code

Use the autoload manager from server-side code:

```gdscript
var payload := {
	"requestId": "run-001",
	"startPosition": {"x": 2, "y": 2},
	"exitPosition": {"x": 16, "y": 16},
	"generationBounds": {
		"origin": {"x": 0, "y": 0},
		"size": {"x": 24, "y": 24}
	}
}

var result: Dictionary = DungeonGenerationManager.generate_dungeon_contract(payload, 1)
if result.get("ok", false):
	var data: Dictionary = result["data"]
	print("Generated layout: ", data.get("layoutId", ""))
else:
	push_warning("Generation failed: %s" % result)
```

### B) Retrieve a generated layout

```gdscript
var layout_id := "layout_run-001_123456"
var lookup: Dictionary = DungeonGenerationManager.get_dungeon_contract(layout_id)
```

### C) Use RPC entry points in multiplayer flow

- Trigger generation: `request_generate_dungeon(payload)`
- Query layout: `request_dungeon_layout(layout_id)`

These are already wired for server-authoritative handling.

### D) Run validation harness scripts

- Connectivity: `test_harness/procedural_dungeon/us1_connectivity_test.gd`
- Layout variety: `test_harness/procedural_dungeon/us2_layout_variety_test.gd`
- Content compliance: `test_harness/procedural_dungeon/us3_content_compliance_test.gd`

Use these scripts to verify acceptance behavior for each story slice.

## Troubleshooting

- **No layout returned**: Check validation error code in result (`error_code` / `code`).
- **No world update visible**: Confirm `LevelManager` autoload is present and `replace_generated_dungeon_container(...)` is available.
- **No monsters spawned**: Confirm a node in group `multiplayer_spawner` exists and includes `spawn_monster_from_scene_path(...)`.
- **Unexpected failures**: Check telemetry logs in `_globals/dungeon_generation_manager.gd` output for request id + failure code.

## Test Harness Scripts

- `test_harness/procedural_dungeon/us1_connectivity_test.gd`
- `test_harness/procedural_dungeon/us2_layout_variety_test.gd`
- `test_harness/procedural_dungeon/us3_content_compliance_test.gd`

## Status

- Phase 1 ✅
- Phase 2 ✅
- Phase 3 ✅
- Phase 4 ✅
- Phase 5 ✅
- Phase 6 ✅

All tasks in `specs/001-procedural-dungeon-generator/tasks.md` are marked complete.
