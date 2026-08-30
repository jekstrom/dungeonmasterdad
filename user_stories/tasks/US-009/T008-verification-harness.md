# T008: Verification harness and independent test

**Story**: US-009  
**Status**: Todo  
**Depends on**: T002–T007  
**Parallel**: no

## Goal

Prove the independent test in automation where possible, and list the play pass that still needs a host session.

## Files

- `test_harness/procedural_dungeon/us009_form_items_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us009_create_form_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us009_fill_channel_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us009_fill_outcomes_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us009_irs_building_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us009_file_tax_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us009_replicate_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us009_independent_test.gd` (+ `.tscn`) — story Independent Test as a scripted sequence
- `test_harness/procedural_dungeon/us009_run_harness.sh` — same pattern as `us007_run_harness.sh`

Headless tests attach the `.gd` to a `.tscn`; do not use a bare `.gd` as the main scene. Testing skill: Node + `.tscn` that prints pass and `quit`s on success.

Keep `us006_run_harness.sh` and `us007_run_harness.sh` green (paper still produces; factories still cost 3 metal; paper cycle still +10 RL).

## Headless checks

- ItemDatabase loads blank / filled / tax; `player_only`; not `auto_use`.
- 1 paper → 1 blank; 0 paper rejected; full inventory drops blank.
- Fill 3s/6s knobs: wait duration still, blank → filled or tax; move/damage/death keeps blank; double complete yields one item.
- Standard complete: Reality +15 (or knob), has filled form.
- Tax complete: Reality unchanged, has tax form.
- 3 metal + legal cell → one IRS; second IRS rejected, metal kept; 2 metal rejected.
- File at enabled IRS: tax 0, Reality +50 (or knob), knob > 10.
- No IRS / ghost / OOR: tax remains.
- Client cannot stick a local Reality bump or extra form.

Independent scripted sequence: grant paper → create blank → fill standard → Reality 15 → grant paper → blank → fill tax → Reality still 15 → place IRS (grant metal) → file → Reality 15+50, tax 0.

## Play pass (host)

Independent test from the story:

1. Start as a Paper Pusher. Get paper (factory or `add_item` cheat if factories are slow). Convert to a blank form. Paper −1, blank +1.
2. Stand still and fill **standard**: after ~3s, filled form in inventory, Reality +15. Move during a second fill: blank remains.
3. Fill a **tax** form (~6s): tax in inventory, Reality **unchanged**.
4. Build IRS in Reality on clear ground with 3 iron. Second IRS button/place does not spawn.
5. Walk to IRS, E with the tax form: form gone, Reality jumps by more than a paper-factory tick (HUD).
6. Try E with no IRS / out of range: tax form would stay (rebuild or drop test).
7. Host+client: client log clean; both see the same Reality after file.

## Requirements

- Independent Test section of US-009
- Testing skill: `godot --path . --headless --quit-after 60 test_harness/procedural_dungeon/<scene>.tscn`

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** a play of the independent test, **When** a Paper Pusher converts, fills, and files, **Then** standard RL, tax hold, and IRS file match the story.

## Notes

Do not claim the story done until this task's headless suite passes and the play pass is run or explicitly called out as not run.

Do not require mines (US-007 play), gremlins (US-013), or Office Max (US-010) to pass. Paper may be granted in tests without running a full factory interval.
