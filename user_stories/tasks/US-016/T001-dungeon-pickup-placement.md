# T001: Place Dew and dice in the generated dungeon

**Story**: US-016  
**Status**: Done  
**Depends on**: none  
**Parallel**: with T002, T003

## Goal

When dungeon generation completes, the layout contains **at least one green Mt Dew** and **at least one die** (`d6` and/or `d20`) on **reachable walkable cells** that are **not** the entrance or exit. Existing start-room Dew (US-014, four cans) stays. Dice are the missing dungeon power-ups so the DM has something to find while exploring.

## Files

- `scripts/procedural_dungeon/pickup_spawn_planner.gd` — today only `plan_start_room_dew`. Keep that start-room Dew list, then add dice (and optional extra Dew) from walkable cells. Prefer a single `plan_dungeon_pickups(...)` that returns the combined `item_pickups` array so `DungeonGenerationManager` has one call site.
- `_globals/dungeon_generation_manager.gd` — currently `layout_data.item_pickups = _pickup_spawn_planner.plan_start_room_dew(...)`. Pass walkable cells, room/hallway regions, entrance, exit, generation seed, and (optional) monster spawn cells so pickups can avoid occupied tiles when there is space.
- `scripts/procedural_dungeon/resources/dungeon_layout_data.gd` — already has `item_pickups` and serializes `itemPickups`. No schema change unless you add fields; keep `item_type` as a `res://pickups/*.tres` path (PickupSpawner / ItemDatabase).
- `test_harness/procedural_dungeon/us016_pickup_placement_test.gd` (+ `.tscn`) — generate via `DungeonGenerationManager.generate_dungeon_contract`, assert Dew + die counts, cells, and reachability.

Reuse `pickups/mtdew.tres`, `pickups/d6.tres`, `pickups/d20.tres`. No new art.

## Requirements

- FR-001, AC1
- Every planned pickup cell MUST be in `walkable_cells` (reachable floor, not a wall).
- Never place on `entrance_cell` or `exit_cell`.
- Keep US-014 start-room Dew: four `res://pickups/mtdew.tres` in the start-room set, not on entrance/exit. `us014_start_room_dew_test.tscn` must still pass (it currently requires **exactly** `START_ROOM_DEW_COUNT` **total** pickups — either keep total Dew-in-start-room at 4 and add dice **outside** that exclusive-count, or update that test to "at least 4 start-room Dew" plus other item types). Prefer: start-room Dew count unchanged; dice live in other walkable cells; if the US-014 test counts **all** `itemPickups`, update it to filter by `item_type` so extra dice do not fail it.
- Suggested defaults: 1 d6 and 1 d20 when cells exist; if only one free cell remains, place one die (either) so the story minimum holds.
- Seeded RNG from `generation_seed` so the same seed is stable.
- Default: one pickup per cell. Two dice in one cell is an **edge case** (both collectable sequentially), not the planner default. Prefer cells not already used by Dew or monster spawns; if the dungeon is tight, skip extras rather than covering entrance/exit.
- Prefer mid / deadend / hallway cells for dice so the DM explores; do not dump dice only on the four start-room Dew neighbors.
- `_spawn_generated_pickups` already emits `SignalBus.on_item_drop` with `item_type` + world center. Do not spawn on clients.

## Acceptance

- **Given** a successful `generate_dungeon_contract`, **When** `itemPickups` is read, **Then** it contains at least one `res://pickups/mtdew.tres` and at least one of `res://pickups/d6.tres` / `res://pickups/d20.tres`.
- **Given** those pickups, **When** each cell is checked, **Then** it is walkable and is not the entrance or exit.
- **Given** the start room, **When** Dew is counted, **Then** the four US-014 start-room Dew still exist (unless the room is smaller than four free cells, same fallback as today).
- **Given** two generations with the same seed and knobs, **When** pickup cells are compared, **Then** they match.

## Notes

Do not implement Dew mana, knightling unlock, or dice Fantasy Level here (T002, T004). Placement only. Quantity knobs belong on the planner (constants, matching `START_ROOM_DEW_COUNT`), not in `level_manager.gd`.
