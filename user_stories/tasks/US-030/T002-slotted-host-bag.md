# T002: Host slotted bag (4 active + 4 static)

**Story**: US-030  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: HUD T003 after the snapshot API exists

## Goal

Each peer (every Paper Pusher **and** the DM) has **four active slots and four static slots** on the host. Grants go to the first empty cell of the item’s row (or stack in a matching cell). If that row is full, `grant_item_or_drop` **drops**. `get_item_count` / `has_resources` / `consume_resources` still work **by item path** so US-006/007/009 stay green.

## Files

- `_globals/player_manager.gd` — replace dict-only `"inventory"` with slotted state, e.g. `active: Array` and `static: Array` of `{ "path": String, "qty": int }` or `null`, length 4 each. Keep a derived dict **or** rewrite count/consume to sum slots. `register_player` initializes empty rows. `add_item_to_inventory`: stack into an existing same-path cell in the **correct** row; else first `null` in that row; else return false. `max_inv_slots` stays 8 (4+4). Push a **slot snapshot** to the owner (extend `update_client_inventory` or add `update_client_slots`).
- `pickups/scripts/item_pickup.gd` — `handle_pickup` for the DM currently uses `sender_id` 1 in the overlap path (`on_body_entered` → `handle_pickup(1, …)`). Grant to the **DM’s unique id** (or the overlapping body’s authority) so the DM bag is that peer, not always `1`.
- `player/inventory/player_inventory.gd` — HUD `InventoryData` must consume the slot snapshot (index-stable), not dict iteration order. Do not reshuffle on every `inventory_updated`.
- `test_harness/procedural_dungeon/us030_slotted_bag_test.gd` (+ `.tscn`)

## Requirements

- FR-001, FR-002, FR-010, AC9
- Same `resource_path` stacks **in one cell** of its row.
- Wrong-row placement is impossible on grant: the host picks the row from `ItemData.inventory_row`.
- Full **active** row + new unique active item → `add_item_to_inventory` false → drop. Empty static cells do not count.
- `has_resources(id, wood, 1)` still true if wood sits in static slot 2. Building spend and factory deposit must not care about index.
- `consume_resources` subtracts from that path’s cell(s); erase empty cells to `null` (do not leave qty 0).
- Host-only writes.

## Acceptance

- **Given** a registered PP, **When** wood then a blank form are added, **Then** wood is in a static cell and the blank in an active cell; counts by path are 1.
- **Given** four distinct active items, **When** a fifth unique active is added, **Then** add fails (or grant drops) and static cells are untouched.
- **Given** two wood added in two calls, **When** static slots are read, **Then** one cell holds qty 2.
- **Given** `has_resources` / `consume_resources` on metal, **When** metal is in static slot 0, **Then** spend still succeeds.

## Notes

HUD chrome is T003. Drag-swap is T007 (`swap_slots` host API can be added here as a stub and used in T007). Do not implement hotkeys here.
