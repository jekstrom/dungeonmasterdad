# T009: Verification harness and independent test

**Story**: US-030  
**Status**: Todo  
**Depends on**: T003–T008  
**Parallel**: no

## Goal

Prove the independent test in automation where possible, and list the play pass that still needs a host session.

## Files

- `test_harness/procedural_dungeon/us030_item_row_flags_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us030_slotted_bag_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us030_hud_rows_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us030_hotkeys_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us030_use_slot_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us030_hold_channel_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us030_drag_swap_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us030_replicate_slots_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us030_independent_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us030_run_harness.sh` — same pattern as `us009_run_harness.sh`

Headless tests attach the `.gd` to a `.tscn`; do not use a bare `.gd` as the main scene.

Keep `us006_run_harness.sh`, `us007_run_harness.sh`, and `us009_run_harness.sh` green (`has_resources` / `consume_resources` still path-based; interact action still deposits/files).

## Headless checks

- Wood/paper/metal **static**; blank form **active** + `channel_use`.
- Grant wood → static cell; blank → active cell; fifth unique active drops.
- Two wood grants stack in one static cell.
- HUD: 8 cells, QERT on top row, different row colors.
- `interact` is not E; inv slots are Q E R T.
- Empty slot use is a no-op; static index cannot be `use_active_slot`.
- Hold for fill duration completes; release keeps blank.
- Swap two active cells; cross-row swap rejected.
- Snapshot preserves index 2; foreign swap rejected.

Independent scripted: register PP → add paper (static) + blank (active) → use/hold blank slot → filled or tax per type → swap two actives → drag static onto active fails.

## Play pass (host)

1. PP: pick up wood and a blank form. Wood bottom, blank top with Q (or whichever cell). Colors differ. **F** (interact) still deposits at a factory; **E** uses active slot 1.
2. Hold the blank’s hotkey still to fill; release early keeps blank.
3. Drag blank from Q to R; R now fills, Q does not.
4. Drag wood onto the blank cell: both stay.
5. DM: pick up a DM active item (dice/cloak if not auto_use) and stone if it bags — same HUD, same QERT, no PP form keys required.
6. Host+client: owner HUD matches after swap; other client does not need to see the bag.

## Requirements

- Independent Test section of US-030
- Testing skill: `godot --path . --headless --quit-after 60 test_harness/procedural_dungeon/<scene>.tscn`

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** a play of the independent test, **When** a PP or DM uses the two-row bag, **Then** grant row, hotkey, hold-channel, and drag rules match the story.

## Notes

Do not claim the story done until this task’s headless suite passes and the play pass is run or explicitly called out as not run.

Do not require IRS filing or factory production in the independent script if grant-item cheats are enough; US-009 harness stays the form/IRS proof.
