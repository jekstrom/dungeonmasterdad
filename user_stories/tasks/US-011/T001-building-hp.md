# T001: Server-side building HP and health bar

**Story**: US-011  
**Status**: Done  
**Depends on**: none  
**Parallel**: with T002

## Goal

Enabled buildings have **server-side hit points** and a **visible health bar**. Nothing deals damage yet. Ghosts stay at full HP and do not show a bar. Defaults match the story: smoke **8**, paper **12**, IRS **20**.

## Files

- `buildings/building.gd` — `hitpoints` already exists (`@export var hitpoints: int = 10`) with no clamp, no max, no bar. Add `@export var max_hitpoints: int = 10`. Clamp in a setter like `Enemy.hp` (`monsters/enemy.gd`). `health_ratio()` + spawn `res://monsters/enemy_health_bar.tscn` (story: reuse; do not fork a building bar). Hide the bar when `is_ghost` or not `is_operating()`. Offset it above the factory sprite so it does not cover `FactoryStatusHud` wood/paper icons (`WORLD_LIFT` is `(0, -78)`).
- `buildings/building.gd` — `add_to_group("buildings")` in `_enter_tree` (keep existing `"factories"` for smoke/paper). T002 searches this group.
- `buildings/buildables/smoke_factory.tscn` — `max_hitpoints = 8`, `hitpoints = 8` (interval stays **3.0**).
- `buildings/buildables/paper_factory.tscn` — `max_hitpoints = 12`, `hitpoints = 12` (interval stays **6.0**).
- `buildings/buildables/irs.tscn` — `max_hitpoints = 20`, `hitpoints = 20`.
- Optional: `@export var max_hitpoints` on `BuildingData` is **not** required; scene exports match how `interval` already works. If Office Max (`US-010`) is already a scene, set 16; do not create it.
- `test_harness/procedural_dungeon/us011_building_hp_test.gd` (+ `.tscn`) — instance each factory/IRS, `enable()`, assert max/current HP; ghost / `set_ghost()` has no visible bar; `health_ratio` at full is 1.0.

## Requirements

- FR-001, FR-006 (bar node exists now; peer replication is T006)
- Host is the writer. Do not let `_process` on a client change HP. A setter that refreshes the local bar is fine (same as `Enemy.hp`).
- `enable()` must not reset HP if something already damaged the building (T003); initializing max/current when `max_hitpoints` is unset is OK in `_ready`.
- Do not add a Hitbox yet (T003). Do not `queue_free` at 0 (T004).
- Do not retune `interval`, `smoke_consume_amt`, `wood_consume_amt`, or Reality grants.
- `is_operating()` stays “not a ghost” until T004 adds destroyed.

## Acceptance

- **Given** an enabled smoke factory, **When** it is read, **Then** `max_hitpoints` is 8 and `hitpoints` is 8.
- **Given** an enabled paper factory, **When** it is read, **Then** HP is 12 / 12.
- **Given** an enabled IRS, **When** it is read, **Then** HP is 20 / 20.
- **Given** a ghost factory (`is_ghost` or name `"ghost"`), **When** the health bar is queried, **Then** it is hidden (or not spawned).
- **Given** an enabled factory, **When** the bar is queried, **Then** it exists, `health_ratio` is 1.0, and the node is `enemy_health_bar.tscn` (or an instance of that script).

## Notes

Damage is T003. Rubble is T004. Replication of `hitpoints` on `MultiplayerSynchronizer` is T006; adding the property path here is allowed if it is easier, but late-join tests wait for T006.

Keep `us006_paper_production_test.tscn` / `us006_deposit_wood_test.tscn` green: `enable()` and `is_ghost` behavior must still produce/deposit.
