# T003: Knightling unlock gate in catalog and DmUnlocks

**Story**: US-016  
**Status**: Done  
**Depends on**: none  
**Parallel**: with T001, T002

## Goal

Knightling summon is an **unlockable** ability, same pattern as fireball. The catalog points `knightling` at unlock id `knightling`. `DmUnlocks` owns the flag. `try_cast("knightling")` already refuses when `unlock_id` is set and the flag is false — wire the table; do not reimplement `try_cast`.

US-014 left this empty on purpose so mana-only knight spawn worked. This task **supersedes** that: knightling now needs unlock **and** mana (FR-008 in US-014).

## Files

- `dm/dm_ability_catalog.gd` — add `UNLOCK_KNIGHTLING: String = "knightling"`; set `KNIGHTLING` entry `"unlock_id"` to that constant (cost stays 40).
- `_globals/DMUnlocks.gd` — include `"knightling": false` in the `_ready` map next to `fireball` / `shadow_zone`. `unlock("knightling")` already RPCs `on_dm_unlock` and emits `SignalBus.on_dm_unlock`. Calling unlock when already true MUST stay true (no toggle).
- `_globals/dm_manager.gd` — `try_cast` already reads `AbilityCatalog.unlock_id`. No new spend path. `unlock()` already forwards to `DmUnlocks.unlock` on the server.
- `test_harness/procedural_dungeon/us016_knightling_unlock_gate_test.gd` (+ `.tscn`) — catalog id, refuse without unlock even with mana 40, succeed after `DmUnlocks.unlock("knightling")`, second unlock stays true, no Fantasy Level tax.
- **Update** US-014 tests that assert empty knightling unlock so the existing harness does not go red:
  - `test_harness/procedural_dungeon/us014_ability_catalog_test.gd` — expect `unlock_id == "knightling"` (not empty).
  - `test_harness/procedural_dungeon/us014_try_cast_test.gd` — treat knightling like fireball: locked refuse with mana; only gremlin remains ungated.
  - `test_harness/procedural_dungeon/us014_summon_spend_test.gd` — unlock knightling before the HUD knight press that expects a spawn; 0-mana refuse can stay locked or unlocked (mana still blocks).
  - `test_harness/procedural_dungeon/us014_independent_test.gd` — knight HUD at 0 mana may stay a refuse; do not require a knight spawn unless unlocked (that story's independent test never needed the unlock).

## Requirements

- FR-002 (unlock path exists), FR-006 (server flag), AC3 (idempotent true)
- Unlock id string is `knightling` (ability id and unlock key match, like fireball).
- Gremlin stays ungated. Fireball / blizzard / dad_all_powerful unlock ids unchanged.
- `try_cast("knightling")` with mana 40 and locked: **false**, mana unchanged, no `spawn_knight_cast`.
- `try_cast("knightling")` with mana 40 and unlocked: **true**, mana 0, still no Fantasy Level deduction.
- Do not grant the unlock from Dew here (T004). Do not hide the HUD button here (T005).
- Match-reset of the flag is T007 (`host_started`). This task only makes the key exist and default false.

## Acceptance

- **Given** the catalog, **When** `unlock_id("knightling")` is read, **Then** it is `knightling` and `cost` is still 40.
- **Given** knightling locked and mana 40, **When** `try_cast("knightling")` runs on the host, **Then** it returns false, mana stays 40, no knight spawn signal.
- **Given** `DmUnlocks.unlock("knightling")` then mana 40, **When** `try_cast("knightling")` runs, **Then** it returns true and mana is 0.
- **Given** knightling already unlocked, **When** `unlock("knightling")` runs again, **Then** the flag stays true (not locked).
- **Given** `us014_run_harness.sh`, **When** it runs after this catalog change, **Then** those scenes still exit 0.

## Notes

`DmUnlocks.unlock` always RPCs even if already true — that is fine (HUD stays shown). Do not add a Fantasy Level cost on the unlock itself (story edge case). Print in `on_dm_unlock` already exists; do not add new debug prints.
