# T001: Wood and paper item resources

**Story**: US-006  
**Status**: Done  
**Depends on**: none  
**Parallel**: with T002

## Goal

**Wood** and **paper** exist as distinct `ItemData` resources Paper Pushers can carry. They are world pickups and inventory stacks, not a shared global pool like smoke. Art already exists; wire it. Do not harvest or produce yet.

## Files

- `pickups/wood.tres` (new) — `ItemData` at the `pickups/` folder root so `ItemDatabase.load_items_from_folder("res://pickups/")` sees it. `name` Wood; `pickup_char = "player_only"`; `auto_use = false`; `texture = pickups/wood/wood.png` (**32×32**); pickup sound like `pickups/metal.tres` / `pickups/coal.tres`. Short description: input for paper factories.
- `pickups/paper.tres` (new) — same pattern. `name` Paper; `pickup_char = "player_only"`; `auto_use = false`; `texture = pickups/paper/paper.png` (**32×32**), **not** `sprites/paper-sheet.png` (that is the factory strip, 100×100 frames). Distinct from wood.
- `pickups/wood/wood.png` and `pickups/paper/paper.png` — already exist. Do not redraw.
- `_globals/item_database.gd` — no code change if the `.tres` files sit in `pickups/`. It does **not** recurse into `pickups/wood/` or `pickups/paper/`.
- `gui/player/player_hud.gd` — `update_paper_count` currently reads `PlayerManager.paper_amt`, which does not exist. Do **not** add a global `paper_amt` / `max_paper_amt` pool. Leave the unused `PaperCount` hidden, or bind it later to the owning player's inventory paper stack (T007). Inventory UI already renders carried items via `SignalBus.inventory_updated`.
- `test_harness/procedural_dungeon/us006_wood_paper_items_test.gd` (+ `.tscn`) — database load, names, textures, `player_only`, not `auto_use`, wood ≠ paper.

## Requirements

- FR-004, FR-006
- Wood and paper MUST be different `resource_path`s and different `name`s so they do not stack into one slot.
- Paper Pushers pick them up through the existing `ItemPickup` + `PlayerManager.add_item_to_inventory` path (`player_only`, not `auto_use`).
- The DM MUST NOT collect them (`pickup_char = "player_only"`; existing `item_pickup.gd` already skips the wrong role).
- No use-effects. Do not restore mana, raise Reality, or convert to forms (US-009).
- Suggested HUD: existing inventory slots are enough for MR-002 until T007. Do not invent a second smoke-style global paper meter.

## Acceptance

- **Given** `pickups/wood.tres` and `pickups/paper.tres`, **When** `ItemDatabase.get_item` is called with those paths, **Then** both resolve, both are `player_only`, neither is `auto_use`, and their textures are the 32×32 pickup sprites (not `sprites/paper-sheet.png`).
- **Given** a Paper Pusher inventory, **When** wood is added via `PlayerManager.add_item_to_inventory`, **Then** the owner HUD / inventory list shows a wood stack (existing `update_client_inventory` path).
- **Given** a Paper Pusher inventory that already has wood, **When** paper is added, **Then** they occupy separate stacks.
- **Given** a DM overlap on a wood or paper `ItemPickup`, **When** pickup is resolved, **Then** the DM does not take the item.

## Notes

Do not harvest trees (T002) or emit paper from the factory (T006). Tests may instance `pickups/pickup.tscn` with the `.tres`. Prefer the shared pickup scene; do not require `pickups/wood/wood.gd`.
