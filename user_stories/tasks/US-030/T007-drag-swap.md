# T007: Drag-swap within a row

**Story**: US-030  
**Status**: Todo  
**Depends on**: T002, T003  
**Parallel**: with T005–T006

## Goal

Click-drag an item onto another cell: **same row** → move (empty) or **swap** (occupied). **Cross-row** → both stacks stay. Drag off the grid or onto self → snap back / no-op. Host applies the swap; the HUD does not only shuffle locally.

## Files

- `_globals/player_manager.gd` — host `swap_slots(player_id, from_index, to_index) -> bool`. Indices 0–7 (0–3 active, 4–7 static) or (row, col). Reject if `from == to`; reject if rows differ; reject if sender is not owner. Swap array entries (including `null`). Then push snapshot.
- `player/inventory/inventory_slot_ui.gd` / `inventory_ui.gd` — `gui_input` drag preview (item icon), drop target. On drop, RPC swap. Do not change qty client-side except by applying the host snapshot.
- `test_harness/procedural_dungeon/us030_drag_swap_test.gd` (+ `.tscn`) — two active items swap; active onto static rejected; empty target is a move; self-drop no-op.

## Requirements

- FR-007, AC7, AC8
- Merge-same-path is **optional**; swap is enough.
- FOCUS_NONE so drag does not leave a focused button eating keys.
- PP and DM use the same slot UI.

## Acceptance

- **Given** item A in active 0 and B in active 2, **When** the host swaps 0 and 2, **Then** B is in 0 and A in 2.
- **Given** wood in static 0 and a blank in active 0, **When** swap(active0, static0) is requested, **Then** it fails and both cells are unchanged.
- **Given** A in active 0 and active 1 empty, **When** swapped, **Then** A is in 1 and 0 is empty.

## Notes

No world drop on drag-off-HUD. Channel cancel if the filling cell moves is T006.
