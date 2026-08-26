# Dungeon Master Dad

Dungeon Master Dad is a Godot 4.5 multiplayer RPG where a dungeon master and players share a session in a state machine-driven world. The project uses ENet networking on port 42069 and relies on singleton managers for core systems.

## Build (Export)

Godot exports are performed via the CLI. Ensure you have the Godot 4.5 export templates installed first.

```bash
godot --path /path/to/dungeon-master-dad --export-release "Linux/X11"
```

## Run (CLI)

Run the main project directly with Godot:

```bash
godot --path /path/to/dungeon-master-dad
```

Run in headless mode (server):

```bash
godot --path /path/to/dungeon-master-dad --headless
```

## Procedural Dungeon Generation Runtime & Debug Workflow

The procedural dungeon pipeline is server-authoritative and routed through `DungeonGenerationManager` (autoload).

### Runtime flow

1. Client/host submits generation payload (`requestId`, `startPosition`, `exitPosition`, `generationBounds`).
2. Server validates input and authority.
3. Server builds room/hallway layout, validates start→exit connectivity, and classifies regions.
4. Server maps layout to existing tile catalog and plans monster spawns from existing monster catalog.
5. Server commits generated scene via `LevelManager.replace_generated_dungeon_container(...)`.
6. Server emits success/failure through `SignalBus` dungeon generation signals.

### Telemetry and debugging

- File: `_globals/dungeon_generation_manager.gd`
- Success logs include request id, layout id, elapsed milliseconds, and aggregate totals.
- Failure logs include request id, failure code, elapsed milliseconds, and message.
- Failure code aggregation is stored in the manager `telemetry.failure_codes` dictionary.

### Validation harness scripts

- `test_harness/procedural_dungeon/us1_connectivity_test.gd`
- `test_harness/procedural_dungeon/us2_layout_variety_test.gd`
- `test_harness/procedural_dungeon/us3_content_compliance_test.gd`

Use these scripts as focused acceptance checks for each user-story slice of the procedural dungeon feature.
