# T007: Verification harness and independent test

**Story**: US-004  
**Status**: Todo  
**Depends on**: T002–T006  
**Parallel**: no

## Goal

Prove the independent test headless where possible, and list the two-window play pass.

## Files

- `test_harness/procedural_dungeon/us004_fantasy_drift_test.gd` (+ `.tscn`) — Node script that quits on success (same pattern as US-002 T007 / US-001 T009)
- Optional shell wrapper matching `us024_run_harness.sh`

## Headless checks

- Outside Fantasy-claimed cell (center inside home, not dungeon, not Reality-claimed) becomes eligible; dungeon cell with Fantasy-claimed center does not; Reality-claimed outside cell does not.
- Many eligible cells do not convert on the same frame (delays differ).
- Convert at most once while claim stays Fantasy; already-Fantasy tiles do not flicker.
- Pocket expire before delay: pending Fantasy drift cancelled; art not applied.
- Applied variant is Fantasy-element of the same kind/variety; collision/kind unchanged; missing strip stays current.
- Homes overlap, no pocket, tied levels: no drift. Higher Fantasy Level: Fantasy-eligible.
- After Fantasy claim is gone and Reality still claims: not Fantasy-eligible; Reality-drift eligible (US-002).
- Snapshot includes current presentation for outside tiles.
- Scheduler is not scanning every outside tile every physics frame (claim/map-change driven).

## Play pass (host + client, two windows)

- Fantasy home over mixed outside + dungeon: outside stagger-converts to Fantasy grass/dirt; dungeon stone stays.
- Fantasy pocket over Reality-looking grass: those cells Fantasy-drift; on expire, they stop Fantasy-drifting and become eligible for Reality drift if Reality still claims them.
- Late join: same variants as host; client log clean.
- Puff visible if enabled; conversion still reads without it.

## Requirements

- Independent Test section of US-004
- Testing skill: new tests under `test_harness/procedural_dungeon/` as Node + `.tscn` that quit on success

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** a two-window play of the independent test, **When** both roles watch home and pocket drift, **Then** both windows agree and the joiner matches the host.

## Notes

Do not claim the story done until headless passes and the play pass is run or explicitly called out as not run. Reality conversion itself is US-002; this harness only needs Fantasy eligibility to drop and Reality eligibility to become true after pocket expire.
