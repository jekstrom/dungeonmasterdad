# T007: Verification harness and independent test

**Story**: US-031  
**Status**: Todo  
**Depends on**: T001–T006, T008  
**Parallel**: no

## Goal

Prove the independent test headless (no boss), keep US-017 blizzard scenes green, and list the two-window play pass.

## Files

- Keep green:
  - `test_harness/procedural_dungeon/us017_blizzard_cast_test.tscn`
  - `us017_blizzard_factory_test.tscn`
  - `us017_blizzard_hud_test.tscn`
  - `us017_blizzard_replicate_test.tscn`
  - `us017_blizzard_test.tscn` (US-017 independent still includes boss+cast)
- New: `us031_cast_gate_test.gd` (+ `.tscn`) if T001 added the empty-clip spend case
- `us031_independent_test.gd` (+ `.tscn`) — story Independent Test: **skip boss**, `DmUnlocks.unlock("bemidji_blizzard")`, mana 100, cast, slow, factory, expire
- `us031_blizzard_vfx_test.gd` (+ `.tscn`) — T008: ice overlay on pocket cells; fall VFX present while live; gone on expire
- `us031_run_harness.sh` — same grep-passed pattern as `us017_run_harness.sh`

Headless tests attach the `.gd` to a `.tscn`. Testing skill: print pass and `quit` on success.

## Headless checks

- Locked: no pocket, mana unchanged.
- Unlocked, mana 10: no pocket, mana 10.
- Unlocked, mana 100, legal rect: mana 70, 3×3 (or clipped) Fantasy pocket, overlay blizzard, duration ~8s.
- Empty clip / off-map: mana unchanged.
- PP in rect: speed 150 if baseline 300; not displaced. PP outside: 300.
- Building footprint in pocket: rejected. Existing factory not destroyed.
- Factory origin in pocket: 2× interval; 90% complete does not reset to 0. Outside factory unchanged.
- Expire: pocket 0, speeds and intervals baseline, ice gone, falling flakes/icicles gone.
- Live pocket: ground overlay is ice (`blizzard_overlay.png`); snow/icicles emit inside the rect only (T008).
- Late-join snapshot includes unlock + live pocket + slows.
- `try_cast` does not add Fantasy Level.

## Play pass (host + client, two windows)

US-017 play still fights the exit boss. This story’s play:

1. Host as DM with blizzard already unlocked (or kill the boss once). Mana from Dew if needed.
2. Cast on Reality home: **ice on the ground**, **snow/icicles falling** in the rect, PP walks through slowed, buildings won’t place, factories tick slower.
3. Second window matches pocket, ground ice, slow, factory timing (flake timing need not match). Expire clears ice, fall VFX, and speeds.
4. Client log clean (`ERR_BUG` / `has_node` / invalid synchronizer).

## Requirements

- Independent Test section of US-031
- Testing skill: `godot --path . --headless --quit-after 60 test_harness/procedural_dungeon/<scene>.tscn`

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** a two-window play of the independent test, **When** both roles watch cast, slow, factory, and expire, **Then** both windows agree.

## Notes

Do not claim the story done until this task’s headless suite passes and the play pass is run or explicitly called out as not run.

Do not require the Baja Blast fight (US-017), cozy, cube, or fireball. Do not fail if PP is inside the pocket (T011).
