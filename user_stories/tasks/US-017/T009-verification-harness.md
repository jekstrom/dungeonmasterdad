# T009: Verification harness and independent test

**Story**: US-017  
**Status**: Todo  
**Depends on**: T005–T008  
**Parallel**: no

## Goal

Prove the independent test headless where possible, and list the two-window play pass.

## Files

- `test_harness/procedural_dungeon/us017_blizzard_test.gd` (+ `.tscn`) — Node script that quits on success (same pattern as US-001 T009)
- Optional shell wrapper matching `us001_run_harness.sh`
- Use skip-boss where the harness only needs the spell.

## Headless checks

- Generation without skip: exactly one boss at exit, not entrance. Skip-boss: zero bosses.
- Death: `bemidji_blizzard` unlocked; can granted.
- Locked or short mana: no pocket, no spend.
- Cast: mana ~30, Fantasy pocket ~8s, axis-aligned, not a circle.
- PP in the rect: not displaced; move speed ~50%. PP outside: baseline.
- Building footprint in pocket: rejected. Existing factory not destroyed.
- Skeleton in pocket without Reality claim: allowed.
- Factory origin in pocket: 2× interval; 90% complete does not reset to 0. Outside factory unchanged.
- Expire: pocket gone, speeds and intervals baseline, same tick.
- Late-join snapshot includes unlock + live pocket.

## Play pass (host + client, two windows)

- Fight the exit boss (south placeholder OK). Death unlocks HUD blizzard icon; can appears.
- Cast on Reality home: ice overlay, PP walks through slowed, buildings won't place, factories tick slower.
- Second window matches pocket, slow, and factory timing. Expire clears ice and speeds.

## Requirements

- Independent Test section of US-017
- Testing skill: new tests under `test_harness/procedural_dungeon/` as Node + `.tscn` that quit on success

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** a two-window play, **When** both roles watch unlock, cast, slow, and expire, **Then** both windows agree and the joiner matches the host.

## Notes

Do not require cozy, cube, or fireball. Do not fail if PP is inside the pocket (T011). Do not require a game-over path.
