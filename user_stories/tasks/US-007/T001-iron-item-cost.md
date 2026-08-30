# T001: Iron item and building metal cost

**Story**: US-007  
**Status**: Todo  
**Depends on**: none  
**Parallel**: with T002

## Goal

**Iron** is the inventory item buildings spend. Reuse existing `pickups/metal.tres` (pickup art already exists). Do not add a second iron `.tres`. Smoke and paper factory `BuildingData` already point at this path with `cost_qty` 3 — keep that. Do not harvest mines yet.

## Files

- `pickups/metal.tres` — already `ItemData`, `name` Metal, `pickup_char = "player_only"`, `auto_use` false, texture `pickups/metal/metal_01.png` (**32×32**), pickup sound `pickups/metal/pickup.wav`. Story language is **iron**; keep the resource path and name unless a one-line description tweak (“iron for buildings”) is clearer. `ItemDatabase.load_items_from_folder("res://pickups/")` already sees it.
- `buildings/buildables/SmokeFactory.tres` / `PaperFactory.tres` — `cost_item = "res://pickups/metal.tres"`, `cost_qty = 3`. Confirm; do not switch to wood.
- `buildings/building_data.gd` — `cost_item` / `cost_qty` already exist.
- `_globals/player_manager.gd` — `grant_item_or_drop` / `has_resources` / `consume_resources` / `carried_count` already work by `resource_path`. No new pool.
- `test_harness/procedural_dungeon/us007_iron_item_test.gd` (+ `.tscn`) — database load, `player_only`, not `auto_use`, factory `.tres` costs.

## Requirements

- FR-003, AC4/AC5 (cost identity only)
- Iron MUST be `res://pickups/metal.tres` so harvest grants and building spends the same stack.
- Paper Pushers pick it up via existing `ItemPickup` (`player_only`, not `auto_use`).
- The DM MUST NOT collect it.
- Do not invent a global iron meter. Inventory slots are the HUD.

## Acceptance

- **Given** `pickups/metal.tres`, **When** `ItemDatabase.get_item` is called with that path, **Then** it resolves, is `player_only`, and is not `auto_use`.
- **Given** `SmokeFactory.tres` and `PaperFactory.tres`, **When** `cost_item` / `cost_qty` are read, **Then** they are `res://pickups/metal.tres` and **3**.
- **Given** a Paper Pusher inventory, **When** metal is added via `PlayerManager.add_item_to_inventory`, **Then** the owner inventory shows that stack.
- **Given** a DM overlap on a metal `ItemPickup`, **When** pickup is resolved, **Then** the DM does not take it.

## Notes

Do not spawn mines (T002) or deduct on place (T007) here. Tests may instance `pickups/pickup.tscn` with `metal.tres`.
