# T002: Mine doodad scene and art

**Story**: US-007  
**Status**: Todo  
**Depends on**: none  
**Parallel**: with T001

## Goal

A **mine** exists as a y-sorted overworld doodad with **active** and **depleted** 128×128 art and a harvest `Hitbox` the pencil melee can hit. No yield, deplete, or map scatter yet. Placeholder art is allowed if generation of the node still succeeds; prefer `sprites/mine_active.png` / `sprites/mine_depleted.png` (story table, 128×128, same 3/4 weight as `sprites/smoke_factory.png`).

## Files

- `doodads/mine.gd` / `doodads/mine.tscn` (new) — `class_name MineDoodad extends Node2D`. Mirror `doodads/tree.tscn` structure: sprite, small `StaticBody2D` on **layer 16** (doodad collision, not a full-cell wall), harvest `Hitbox` on **layer 8** (`player.tscn` `AttackHurtbox.collision_mask = 8`). Do not put the mine on player-damage layer 256.
- `sprites/mine_active.png` / `sprites/mine_depleted.png` — 128×128. Wire both; default visual is active. Depleted swap is T004.
- `test_harness/procedural_dungeon/us007_mine_doodad_test.gd` (+ `.tscn`) — instance the scene, type `MineDoodad`, Hitbox layer 8, StaticBody layer 16, active texture.

## Requirements

- FR-001 (node exists), story art table
- Footprint: one floor cell. Collision is a small pit/base, not a dungeon wall.
- Y-sort like `tree.tscn` / `smoke_factory.tscn` (sprite offset so feet sit on the cell).
- `add_to_group("harvest_trees")` is the wrong name; use `harvest_nodes` (trees may join later) **or** a `mines` group plus T003 updates the SPACE prompt to query mines. Prefer group `harvest_nodes` and have T003 also add trees to it **or** check both `harvest_trees` and `mines`.
- Do not implement hits, iron grant, or deplete here (T003 / T004).

## Acceptance

- **Given** `doodads/mine.tscn`, **When** it is instanced, **Then** it is a `MineDoodad` with a layer-8 `Hitbox` and layer-16 doodad body.
- **Given** the mine sprite, **When** it is read, **Then** it uses the 128×128 active mine texture (depleted asset is present on disk / export even if unused until T004).

## Notes

Tree harvest stays US-006. Placement scatter is T006. Tests instance the scene; do not require map fill.
