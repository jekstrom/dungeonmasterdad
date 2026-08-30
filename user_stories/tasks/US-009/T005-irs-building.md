# T005: IRS building — unique, iron cost, placeable

**Story**: US-009  
**Status**: Todo  
**Depends on**: none  
**Parallel**: with T001–T004

## Goal

The **IRS** is a placeable building: 128×128 art, iron cost like factories, **at most one enabled IRS** per match. Placement uses existing US-001 / US-003 rules (`BuildingManager.is_area_clear`). Ghost preview is not “enabled”. Filing is T006.

## Files

- `sprites/irs_building.png` — already 128×128. Use as the building sprite (own silhouette; do not reuse `smoke_factory.png`).
- `sprites/irs_icon.png`, `sprites/irs_icon_pressed.png` — HUD buttons.
- `buildings/buildables/irs.gd` — `class_name IrsBuilding extends Building`. `add_to_group("irs")` (and keep `Building` enable/ghost/blizzard hooks). No smoke production. `is_operating()` / `enable()` like factories.
- `buildings/buildables/irs.tscn` — Node2D/Building with sprite, `CollisionShape2D`, `AnimationPlayer` stub if `Building` requires it (see `smoke_factory.tscn`). Y-sort like other buildings. `MultiplayerSynchronizer` at least `position` + `is_ghost` (paper factory pattern).
- `buildings/buildables/Irs.tres` — `BuildingData`: `scene` = irs.tscn, `cost_item = "res://pickups/metal.tres"`, `cost_qty = 3`, `size = Vector2i(128, 128)`. Filename **`Irs.tres`** so `Player.setup_building` can `load("res://buildings/buildables/" + building + ".tres")` with HUD emit `"Irs"`.
- `_globals/building_manager.gd` — before consume/spawn, if this `BuildingData` is the IRS, reject when an **enabled** IRS already exists in `building_root` (ghosts do not count; `is_operating()` or `not is_ghost`). Atomic with `has_resources` and `is_area_clear`: uniqueness fail → **no** iron spend.
- `_globals/building_database.gd` — auto-loads `*.tres` in `buildables/`; no code change if `Irs.tres` is there. Keys are `resource_path`; placement RPC uses that path (existing player code).
- `gui/player/player_hud.gd` / `player_hud.tscn` — third build button (FOCUS_NONE, `release_focus` on press like smoke/paper). `SignalBus.build_irs_building_pressed` (new) or reuse a generic signal. `Player.setup_building` already accepts any `"Name"` that matches a `.tres`.
- `playground.tscn` `BuildingSpawner` `_spawnable_scenes` — include `irs.tscn` so clients can spawn it.
- `test_harness/procedural_dungeon/us009_irs_building_test.gd` (+ `.tscn`)

## Requirements

- FR-007, MR-003, AC7 (building exists / uniqueness; filing fail is T006)
- Place only in Reality on outside tiles, not Fantasy, not dungeon — existing `is_area_clear`.
- Cost 3 metal. Too little iron → no spawn (US-007 T007 behavior).
- Second enabled IRS rejected; iron unchanged.
- Ghost / preview is not unique and not filable.
- Do not grant Reality on place.
- Do not implement Office Max uniqueness here, but keep the check **data-driven** (`unique` export on `BuildingData` is fine) so US-010 can set the same flag.

## Acceptance

- **Given** 3 metal and a legal Reality cell, **When** the player requests IRS placement, **Then** iron is 0 and one enabled `IrsBuilding` exists.
- **Given** an enabled IRS already in `building_root`, **When** a second IRS is requested with 3 metal, **Then** still one IRS and metal unchanged.
- **Given** 2 metal, **When** IRS is requested on a legal cell, **Then** no building and metal is 2.

## Notes

Filing interact is T006. US-011 destroy: if you count `is_instance_valid` children, a freed IRS frees the unique slot. Do not add goblin damage in this task.
