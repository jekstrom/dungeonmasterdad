# T007: Spend iron on legal building placement

**Story**: US-007  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T003–T006

## Goal

Placing a smoke or paper factory **consumes** `cost_qty` iron (`metal.tres`) only when the placement is **legal**. Too little iron → reject, no spend. Footprint failure → **no** deduction (keep `BuildingManager` atomic: resources **and** `is_area_clear` together). This is the spend half of the independent test.

## Files

- `_globals/building_manager.gd` — `request_placement` already does `has_resources(sender_id, data.cost_item, data.cost_qty) and is_area_clear(...)` then `consume_resources`. Confirm `cost_item` is the metal path. If `has_resources` is host-only and clients see stale HUD, that is existing inventory sync (T008). Do **not** deduct then refund on failed add_child.
- `_globals/player_manager.gd` — `has_resources` / `consume_resources` must erase keys at qty ≤ 0 (already done for wood).
- `buildings/buildables/SmokeFactory.tres` / `PaperFactory.tres` — cost 3 metal (T001).
- `test_harness/procedural_dungeon/us007_building_cost_test.gd` (+ `.tscn`) — grant 3 metal, legal place → building exists, inventory 0; grant 2 metal, request place → no building, inventory still 2; enough metal but footprint blocked (or not Reality / in Fantasy) → no spend.

## Requirements

- FR-003, FR-005, AC4, AC5, edge: last iron on rejected footprint
- Host-authoritative spend.
- Smoke/paper factories keep this iron cost (story assumption). Do not mark them free here.
- IRS / Office Max uniqueness is out of scope; if those `.tres` exist they may also cost metal.

## Acceptance

- **Given** a Paper Pusher with ≥ `cost_qty` metal and a legal Reality outside footprint, **When** they request that building, **Then** metal decreases by `cost_qty` and the enabled building exists.
- **Given** a Paper Pusher with less than `cost_qty` metal, **When** they request placement, **Then** no building is created and metal is unchanged.
- **Given** enough metal but `is_area_clear` is false, **When** they request placement, **Then** metal is unchanged and no building is created.

## Notes

Do not retune `cost_qty`. Harvest is T003/T004; this task may `add_item_to_inventory` metal in tests without a mine.
