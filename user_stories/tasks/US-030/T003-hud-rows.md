# T003: HUD — two rows, colors, hotkey labels

**Story**: US-030  
**Status**: Todo  
**Depends on**: T002  
**Parallel**: with T004

## Goal

The shared `inventory_ui` shows **top = active**, **bottom = static**, **distinct cell backgrounds**, and **Q E R T** in the **upper-left** of the four active cells. PP HUD and DM HUD both pick this up (same scene). No use or drag yet (or disable click-use until T005).

## Files

- `player/inventory/inventory_ui.tscn` / `inventory_ui.gd` — keep `columns = 4`. Children 0–3 active, 4–7 static. Apply row chrome when building slots from the snapshot.
- `player/inventory/inventory_slot.tscn` / `inventory_slot_ui.gd` — `FOCUS_NONE` (and `release_focus` if needed). Quantity label can stay. Add a hotkey `Label` (upper-left). Active cells get Q/E/R/T; static cells no hotkey text. Two background colors (theme/`modulate`/`ColorRect`) — both empty and filled cells keep the row color.
- `gui/player/player_hud.tscn`, `gui/dm/dm_hud.tscn` — no fork; they already instance this scene.
- `test_harness/procedural_dungeon/us030_hud_rows_test.gd` (+ `.tscn`) — instance `inventory_ui.tscn`, apply a snapshot with one active and one static item, assert child count 8, hotkey texts, and that active vs static backgrounds are not the same color.

## Requirements

- FR-003, FR-008, AC1, AC2
- Labels show the **currently bound** InputMap events for the slot actions (T004 names). If T004 is not merged yet, hardcode `"Q"/"E"/"R"/"T"` and switch to `InputMap.action_get_events` in T004.
- Do not call `ItemData.use()` on press in this task (current `item_pressed` client decrement is the bug T005 removes). Safe: disconnect `pressed` or no-op until T005.
- One widget for PP and DM.

## Acceptance

- **Given** the inventory UI, **When** it builds, **Then** there are 8 cells, two rows of 4.
- **Given** active cells 0–3, **When** labels are read, **Then** they are Q, E, R, T in the upper-left.
- **Given** an active cell and a static cell, **When** backgrounds are compared, **Then** they differ.

## Notes

Drag is T007. Do not add new slot art; colors + labels only.
