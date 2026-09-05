# T004: Verification harness

**Story**: US-059  
**Status**: Todo  
**Depends on**: T002, T003  
**Owner**: QA / Gameplay

## Goal

Headless contract that the sheets exist at 512×384, `dm.tscn` is not using `PlayerSprite02` as the live Sprite2D texture, and AnimationPlayer has `idle_*`, `walk_*`, `attack_*`, `cast_*` for down/side/up.

## Files

- `test_harness/procedural_dungeon/us059_dm_wizard_sheet_test.gd`
- `test_harness/procedural_dungeon/us059_dm_wizard_sheet_test.tscn`

## Requirements

- Node + `.tscn` (not a bare `.gd` main scene).
- Assert PNG sizes and that each sheet’s `hframes`/`vframes` on the DM match 4×3 after load, or that clip libraries contain the twelve clip names.
- Do not require Imagine; this is file + scene contract.

## Acceptance

- **Given** `godot --path . --headless --quit-after 20 test_harness/procedural_dungeon/us059_dm_wizard_sheet_test.tscn`, **When** it exits 0, **Then** sheets and clip names match US-059.
