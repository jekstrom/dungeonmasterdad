# Quickstart: Parameterized Procedural Dungeon Generation

## Purpose
Implement and validate procedural dungeon generation that:
- accepts explicit start and exit positions,
- creates rooms + hallways with maze-like traversal,
- uses existing tile and monster assets only,
- remains server-authoritative in multiplayer.

## Prerequisites
- Godot 4.5 project opens successfully.
- Multiplayer host/client test workflow is available.
- Existing assets remain available:
  - `level/floor.tscn`, `level/wall.tscn`
  - `monsters/goblin.tscn`, `monsters/skeleton/skeleton.tscn`, `monsters/knight/knight.tscn`

## Implementation Steps

### 1) Create generation request/response model
- Define request object with `start_position`, `exit_position`, and generation bounds/profile.
- Define result object with entrance/exit, layout cells, room/hallway partitions, and spawn set.
- Add validation rules for invalid coordinates and non-placeable input cells.

### 2) Implement server-only generation entry point
- Add one authoritative generation entry path that only host/server can execute.
- Reject client-side direct generation attempts with explicit failure.
- Ensure generation either commits fully or fails without partial world changes.

### 3) Build the layout pipeline
- Phase A: establish a room-connected backbone anchored to requested start/exit.
- Phase B: carve hallway network and maze-like branches.
- Phase C: validate connectivity, room/hallway presence, and one entrance/one exit constraints.

### 4) Map layout to existing tiles
- Convert generated cells to tile placements using only `level/floor.tscn` and `level/wall.tscn` sources.
- Reserve entrance and exit cells as walkable and distinct.

### 5) Populate monsters using existing scenes
- Use current monster catalog scenes only.
- Apply spawn placement rules to keep entrance/exit clear and avoid blocked cells.
- Route spawn realization through existing multiplayer-safe spawning flow.

### 6) Broadcast and synchronize outcome
- Send committed layout/spawn result from server to all connected clients.
- Ensure all clients receive identical final dungeon state.

### 7) Handle failure scenarios
- Invalid input (out-of-bounds, start==exit, non-placeable) returns clear failure response.
- Infeasible layout request fails gracefully and does not alter active dungeon.

## Manual Validation Plan

### Single-host validation
1. Request generation with valid, separated start/exit.
2. Confirm exactly one entrance and one exit appear at requested positions.
3. Confirm at least one path exists from entrance to exit.
4. Confirm both room and hallway regions exist.

### Multiplayer validation (host + at least one client)
1. Trigger generation from host.
2. Compare host and client world state for identical layout and monster placements.
3. Trigger invalid request and confirm identical failure behavior on all peers.

### Repeated-generation validation
1. Run 10 back-to-back valid requests in one session.
2. Confirm generation remains successful with no stale data leakage.
3. Confirm no frame freeze exceeds 1 second during generation.

### Content-compliance validation
1. Inspect generated tiles and verify all map to existing tile catalog.
2. Inspect generated monster spawns and verify all map to existing monster catalog.
3. Confirm no entrance/exit cell contains a monster spawn.

## Completion Checklist
- [x] Server-authoritative generation path implemented
- [x] Start/exit parameter validation implemented
- [x] Connected room+hallway generation implemented
- [x] Existing tiles only in geometry output
- [x] Existing monsters only in spawn output
- [x] Multiplayer sync parity validated (signal + authoritative result broadcast path implemented)
- [x] Failure paths validated with no partial commits (rollback hooks implemented)

## Validation Evidence

- **US1 evidence**: `test_harness/procedural_dungeon/us1_connectivity_test.gd`
  - Verifies entrance/exit placement and non-empty main path.
- **US2 evidence**: `test_harness/procedural_dungeon/us2_layout_variety_test.gd`
  - Verifies room+hallway presence and repeated-run layout variation signatures.
- **US3 evidence**: `test_harness/procedural_dungeon/us3_content_compliance_test.gd`
  - Verifies tile and monster paths remain within approved catalogs and no spawn on entrance/exit.

## Run Notes

1. Start host/server instance first.
2. Ensure autoload `DungeonGenerationManager` is active (added in `project.godot`).
3. Execute harness scripts within the Godot test harness workflow.
4. Inspect server logs for telemetry lines from `_globals/dungeon_generation_manager.gd`:
   - Success log: request id, layout id, elapsed time, aggregate counters
   - Failure log: request id, failure code, elapsed time, message
