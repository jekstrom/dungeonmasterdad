# T003: Wood yield, stump, and grant-or-drop

**Story**: US-006  
**Status**: Done  
**Depends on**: T001, T002  
**Parallel**: with T004

## Goal

When harvest progress completes, the host yields a configurable amount of **wood** (default **1**, allowed 1–2), then the tree is **unavailable**: remove it or replace it with a **stump** that is not harvestable. If the harvester's inventory cannot take the wood, drop it as a world pickup. Two last hits on the same frame grant wood **once**.

## Files

- `doodads/tree.gd` / `doodads/tree.tscn` — on host complete: set stump (or queue_free), disable harvest Hitbox. Stump sprite: `sprites/tree_stump.png` (**32×32**), same pixel weight / scale as `sprites/tree.png` frames. Do not redraw the living-tree atlas.
- `_globals/player_manager.gd` — `add_item_to_inventory` today no-ops when `inventory.keys().size() >= max_inv_slots` and the item is new. Add a host **grant-or-drop** helper used by harvest (and safe for later mines): if the player already has a wood stack or a free slot, grant; else `SignalBus.on_item_drop` at the tree with `item_type = "res://pickups/wood.tres"` and a world `position`. Never delete the yield.
- `scripts/pickup_spawner.gd` — already listens to `on_item_drop`. Drop payload matches existing `{ "item_type": path, "position": Vector2 }` (see `monsters/baja_boss.gd`).
- `test_harness/procedural_dungeon/us006_wood_yield_test.gd` (+ `.tscn`) — complete harvest → wood in inventory; full unique slots and no wood stack → world pickup; two completing hits → one yield; stump not harvestable.

## Requirements

- FR-003, FR-004, FR-008, AC2, AC3
- Default yield **1** wood (export; 1–2 is the story range). Apply yield **once** per tree.
- Same-frame last hits from two players: first host resolution wins; second sees a stump / missing living tree; **no** duplicate wood.
- Grant to the player who applied the completing hit when inventory can take it. If that player disconnects between hit and grant, drop at the tree; do not delete wood.
- Full inventory means: `max_inv_slots` distinct item ids **and** no existing wood key. Extra wood on an existing stack MUST still grant (current `add_item_to_inventory` already stacks by `resource_path`).
- Stump: not re-harvestable until respawn. **Respawn is out of scope** (story assumption: finite wood if there is no timer). Do not add a respawn clock here.
- Host-authoritative removal/stump and grant/drop.

## Acceptance

- **Given** a tree at `hits_required - 1`, **When** a Paper Pusher lands the last hit and has inventory space, **Then** they receive the configured wood and the tree is a stump (or gone).
- **Given** a Paper Pusher with 8 distinct item types and no wood, **When** a tree completes, **Then** wood appears as a world pickup at the tree and is not lost.
- **Given** a Paper Pusher who already holds wood and is otherwise "full", **When** a tree completes, **Then** the wood stack increases (no extra drop).
- **Given** two players' last hits on the same frame, **When** the host resolves, **Then** there is one yield and one stump.
- **Given** a stump, **When** a Paper Pusher melees it, **Then** harvest progress does not increase and no more wood is granted.

## Notes

Lockouts are T004 (a tree under a building should never reach yield). Factory deposit is T005. Do not emit paper here. Keep `us024_tree_scatter_test.tscn` green: scatter still instances `doodads/tree.tscn`; living trees must still type as `TreeDoodad`.
