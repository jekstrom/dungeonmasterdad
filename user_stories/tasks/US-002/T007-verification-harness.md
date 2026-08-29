# T007: Verification harness and independent test

**Story**: US-002  
**Status**: Todo  
**Depends on**: T002–T006  
**Parallel**: no

## Goal

Prove the independent test headless where possible, and list the two-window play pass.

## Files

- `test_harness/procedural_dungeon/us002_reality_drift_test.gd` (+ `.tscn`) — Node script that quits on success (same pattern as US-001 T009)
- Optional shell wrapper matching `us024_run_harness.sh`

## Headless checks

- Outside Reality-claimed cell (center inside home, not dungeon) becomes eligible; dungeon cell with Reality-claimed center does not.
- Many eligible cells do not convert on the same frame (delays differ).
- Convert at most once while claim stays Reality; already-Reality tiles do not flicker.
- Pocket expire before delay: pending Reality drift cancelled; art not applied.
- Applied variant is Reality-element of the same kind/variety; collision/kind unchanged.
- Homes overlap, no pocket, tied levels: no drift. Higher Reality Level: Reality-eligible.
- Snapshot includes current presentation for outside tiles.

## Play pass (host + client, two windows)

- Reality home over mixed outside + dungeon: outside stagger-converts to mundane grass/dirt; dungeon stone stays.
- Reality pocket over Fantasy-looking grass: those cells Reality-drift; on expire, they stop Reality-drifting (Fantasy drift is US-004).
- Late join: same variants as host; client log clean.
- Optional puff visible if enabled; conversion still reads without it.

## Requirements

- Independent Test section of US-002
- Testing skill: new tests under `test_harness/procedural_dungeon/` as Node + `.tscn` that quit on success

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** a two-window play of the independent test, **When** both roles watch home and pocket drift, **Then** both windows agree and the joiner matches the host.

## Notes

Do not claim the story done until headless passes and the play pass is run or explicitly called out as not run. Do not require US-004 conversions to pass this harness.
