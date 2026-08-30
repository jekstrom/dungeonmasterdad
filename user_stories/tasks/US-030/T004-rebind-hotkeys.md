# T004: Rebind interact and slot hotkeys

**Story**: US-030  
**Status**: Todo  
**Depends on**: none  
**Parallel**: with T001–T003

## Goal

**E** is an inventory slot key, not world interact. **Q E R T** are the four active cells for **every** local player (PP and DM). Colliding US-009 item keys are removed or moved off QERT.

## Files

- `project.godot` `[input]`
  - `interact`: move off physical **E** (69). Suggested **F** (70). PP factory deposit / IRS file and DM `DmManager.interact_pressed` keep using the `interact` **action**, not a raw key.
  - Add `inv_slot_0` … `inv_slot_3` (names up to you) bound to **Q**, **E**, **R**, **T** (physical 81, 69, 82, 84).
  - Remove or rebind `fill_standard` (R), `fill_tax` (T), `create_form` (F) so they do not fire with slot use. Create-form must not stay on F if interact moves to F — pick another unused key or a HUD/static action (story: create-form is **not** QERT).
- `player/scripts/player_idle_state.gd` / `player_walk_state.gd` — keep `interact` for `try_interact`. Stop calling `handle_form_input` for R/T fill if those actions die. Slot use is T005.
- `dm/scripts/dm_idle_state.gd` / `dm_walk_state.gd` — still `is_action_pressed("interact")` only; no code change if the action name is unchanged.
- `player/player.gd` — `handle_form_input` currently maps `create_form` / `fill_standard` / `fill_tax`. After this task those actions may be gone; T005 replaces them with `inv_slot_*`.
- `test_harness/procedural_dungeon/us030_hotkeys_test.gd` (+ `.tscn`) — `InputMap` has `interact` without E; `inv_slot_0..3` are Q E R T. Document create-form’s new bind if any.

## Requirements

- FR-003, FR-009
- Same InputMap for PP and DM (one `[input]` block).
- Factory deposit and IRS file still listen to **`interact`**, not E.
- US-005 `FOCUS_NONE` on HUD buttons remains so QERT is not stolen.

## Acceptance

- **Given** `InputMap`, **When** `interact` events are listed, **Then** none is physical E.
- **Given** slot actions 0–3, **When** their events are listed, **Then** they are Q, E, R, T in order.
- **Given** `fill_standard` / `fill_tax`, **When** they still exist, **Then** they are not R/T (prefer deleted).

## Notes

T005 actually fires uses. T003 labels should read these actions once they exist. Play: E no longer deposits wood — that is **F** (or whatever `interact` becomes).
