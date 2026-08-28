# T008: Verification harness and independent test

**Story**: US-016  
**Status**: Done  
**Depends on**: T001–T007  
**Parallel**: no

## Goal

Prove the independent test in automation where possible, and list the play pass that still needs a host session.

## Files

- `test_harness/procedural_dungeon/us016_pickup_placement_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us016_dice_effect_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us016_knightling_unlock_gate_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us016_dew_unlock_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us016_knightling_hud_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us016_fantasy_home_growth_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us016_unlock_replication_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us016_independent_test.gd` (+ `.tscn`) — story Independent Test as a scripted sequence
- `test_harness/procedural_dungeon/us016_run_harness.sh` — same pattern as `us014_run_harness.sh` / `us024_run_harness.sh`

Headless tests attach the `.gd` to a `.tscn`; do not use a bare `.gd` as the main scene. Testing skill: Node + `.tscn` that prints pass and `quit`s on success.

Also keep `us014_run_harness.sh` green after T003's catalog/test updates.

## Headless checks

- Generated contract: ≥1 green Dew path, ≥1 die path; every pickup cell walkable; none on entrance/exit; start-room Dew count still 4 when the room allows it.
- `d6.tres` / `d20.tres`: `dm_only`, `auto_use`, +6 / +20 Fantasy Level, no mana.
- Paper Pusher overlap on Dew or die: no collect, no FL, no mana, no unlock.
- Catalog: `unlock_id("knightling") == "knightling"`, cost 40.
- Locked + mana 40: `try_cast("knightling")` false.
- First `mtdew.tres.use()` from 0 mana / locked: mana 25, knightling true, Fantasy Level unchanged.
- Second Dew: mana increases, unlock stays true.
- HUD: knight control hidden while locked; visible after unlock; press with mana 40 summons once; 0 mana refuses.
- After a die use with committed interior: Fantasy `home_rect` grew and is still inside interior.
- Host reset: `host_started` clears knightling; late-join payload applies host flags.
- Summon after unlock does not subtract 150 Fantasy Level.

## Play pass (host)

Independent test from the story:

1. Start a match as DM. Knight button hidden. Walk the generated dungeon.
2. Find a green Mt Dew (start room already has cans). Pick it up: mana +25, knight button appears.
3. With mana ≥ 40 (more Dew if needed), press knight: one knightling, mana −40, Fantasy Level not taxed.
4. Find a d6 or d20. Pick it up: Fantasy Level up; Fantasy home rectangle visibly larger (playground zone overlay).
5. Join or spawn a Paper Pusher (second instance or local player): they walk over leftover Dew/dice and do not collect them.
6. Host+client: client log clean (`ERR_BUG` / `has_node` / invalid synchronizer). Late join after Dew still has knightling unlocked on the DM HUD.

## Requirements

- Independent Test section of US-016
- Testing skill: `godot --path . --headless --quit-after 60 test_harness/procedural_dungeon/<scene>.tscn`

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** a play of the independent test, **When** the DM finds Dew and a die, **Then** mana + knight unlock + FL/rectangle growth + Paper Pusher skip match the story.

## Notes

Do not claim the story done until this task’s headless suite passes and the play pass is run or explicitly called out as not run.

Headless suite: `test_harness/procedural_dungeon/us016_independent_test.tscn` plus `us016_run_harness.sh`.

Play pass **not run** until someone hosts playground: dungeon crawl Dew, knight HUD, die + rectangle, host+client skip/collect.
