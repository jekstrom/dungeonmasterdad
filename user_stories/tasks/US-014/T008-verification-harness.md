# T008: Verification harness and independent test

**Story**: US-014  
**Status**: Done  
**Depends on**: T003–T007  
**Parallel**: no

## Goal

Prove the independent test in automation where possible, and list the play pass that still needs a host session.

## Files

- `test_harness/procedural_dungeon/us014_mana_pool_test.gd` (+ `.tscn`) — Node script that quits on success (testing skill)
- `test_harness/procedural_dungeon/us014_try_cast_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us014_dew_effect_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us014_independent_test.gd` (+ `.tscn`) — story Independent Test as a scripted sequence
- `test_harness/procedural_dungeon/us014_run_harness.sh` — same pattern as `us024_run_harness.sh`
- Also in the harness: `us014_ability_catalog_test`, `us014_summon_spend_test`, `us014_fireball_spend_test`, `us014_mana_hud_test`, `us014_start_room_dew_test`

Headless tests attach the `.gd` to a `.tscn`; do not use a bare `.gd` as the main scene.

## Headless checks

- New match / reset: current 0, max 100.
- `add_mana(25)` → 25; `add_mana` at 90 → 100 (clamp).
- Catalog defaults: gremlin 20, knightling 40, fireball 15, blizzard 30, dad_all_powerful 0.
- Mana 0: `try_cast` for gremlin, knightling, fireball, `bemidji_blizzard` all false; mana stays 0.
- Mana 10: gremlin false; mana unchanged.
- Mana 25, fireball **locked**: fireball `try_cast` false; mana unchanged.
- Mana 25, fireball unlocked: fireball true, mana 10; gremlin after that with remaining 10 fails if cost is 20.
- Two `try_cast("gremlin")` with mana 25: first true (mana 5), second false.
- Successful gremlin `try_cast` does not change `fantasy_level`.
- `ItemEffectRestoreMana` / Dew `.tres`: DM-only, auto_use, +25; Paper Pusher `pickup_char` is not `dm_only` consumer.
- Code Red `.tres` has no restore-mana effect.

## Play pass (host)

Independent test from the story:

1. Start a match as DM (mana 0). Gremlin, knight, fireball (if visible), and blizzard-if-present all refuse.
2. Spawn or place a green Mt Dew (`pickups/mtdew.tres` on `pickup.tscn`). Pick it up as DM: mana +25, meter updates. Walk a Paper Pusher over a second can if two instances: they do not take it.
3. With fireball unlocked (debug/Code Red) **or** using gremlin (no unlock): cast once — mana drops by cost, ability happens.
4. Spend down to 0 and refuse again.
5. Confirm Fantasy Level did not pay for the summon (no −150).

Host+client: a joining peer must not be able to RPC-spawn a gremlin at 0 mana; client log clean (`ERR_BUG` / `has_node` / invalid synchronizer).

## Requirements

- Independent Test section of US-014
- Testing skill: new tests under `test_harness/procedural_dungeon/` as Node + `.tscn` that quit on success

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** a play of the independent test, **When** the DM starts at 0, picks up Dew, and casts, **Then** refuse / gain / spend / refuse matches the story.

## Notes

Do not claim the story done until this task’s headless suite passes and the play pass is run or explicitly called out as not run.

Headless suite: `test_harness/procedural_dungeon/us014_independent_test.tscn` plus `us014_run_harness.sh`.

Play pass **not run** this task: no host playground session for Dew pickup in the start room, gremlin/fireball spend, or host+client fake-RPC at 0 mana.

Start-room Dew placement is included in `us014_start_room_dew_test.tscn`. The independent test uses `mtdew.tres.use()` for the mana grant beat.
