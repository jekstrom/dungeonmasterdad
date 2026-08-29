# T007: Verification harness and independent test

**Story**: US-025  
**Status**: Todo  
**Depends on**: T002–T006  
**Parallel**: no

## Goal

Prove the independent test headless where possible, and list the two-window play pass.

## Files

- `test_harness/procedural_dungeon/us025_home_no_overlap_test.gd` (+ `.tscn`) — Node script that quits on success (same pattern as US-001 T009)
- Optional shell wrapper matching `us001_run_harness.sh`

## Headless checks

- After resolve, Reality home ∩ Fantasy home is empty (center-point).
- Higher Reality Level: contested cells in Reality home only; Fantasy rect shrunk on the west face.
- Higher Fantasy Level: contested cells in Fantasy home only; Reality rect shrunk on the east face.
- Equal levels: growth into the other is clipped; existing overlap retracts; at most one unclaimed odd-width leftover.
- Pocket over the other home: claim follows pocket; home rects unchanged by the pocket; after expire, no-overlap homes remain.
- Outside cell with Fantasy art and no Fantasy claim is corrected (not left until the other drift).
- Same for Reality art without Reality claim.
- Resolve is not scanning every outside tile every physics frame.
- No game-over flag or match-end when a home is large.

## Play pass (host + client, two windows)

- Grow both homes until they meet: abut, no shared cells, overlays do not stack on one cell.
- Raise one level: winner takes the band, loser shrinks.
- Equal: frontier holds.
- Pocket over the other home, then expire: occupancy/drift follow pocket, then homes.
- James case: no Fantasy grass/dirt sitting in a cell that is not Fantasy-claimed. Late join matches host.

## Requirements

- Independent Test section of US-025
- Testing skill: new tests under `test_harness/procedural_dungeon/` as Node + `.tscn` that quit on success

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** a two-window play of the independent test, **When** both roles watch pushback and the linger bug, **Then** both windows agree and the joiner matches the host.

## Notes

Do not claim the story done until headless passes and the play pass is run or explicitly called out as not run. Do not require a game-over path.
