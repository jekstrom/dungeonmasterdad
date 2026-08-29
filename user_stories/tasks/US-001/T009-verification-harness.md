# T009: Verification harness and independent test

**Story**: US-001  
**Status**: Todo  
**Depends on**: T005–T008  
**Parallel**: no

## Goal

Prove the independent test headless where possible, and list the two-window play pass.

## Files

- `test_harness/procedural_dungeon/us001_reality_claim_test.gd` (+ `.tscn`) — Node script that quits on success (same pattern as US-024 T015)
- Optional shell wrapper matching `us024_run_harness.sh`

## Headless checks

- Claim API ignores any leftover circle; home-only cells match the west-anchored rect.
- Home rebuilds with Reality Level and stays inside map interior.
- Pocket create clips to interior; overlap prefers the newer pocket; expire drops that rect from claim.
- Skeleton spawn on a claimed cell is rejected; a skeleton moved onto claim is removed; goblin on claim is not.
- Building footprint fully in Reality on outside tiles accepts; partial / dungeon rejects.

## Play pass (host + client, two windows)

- Paper Pusher walks the rectangular home; DM walks in and stays controllable.
- Legal building places; illegal footprint does not.
- Skeleton that enters (or is covered by growth/pocket) vanishes on both windows.
- Pocket appears with distinct overlay; on expire, claim and overlays match remaining coverage.
- Late join: same home, pockets, living skeletons; client log clean.

## Requirements

- Independent Test section of US-001
- Testing skill: new tests under `test_harness/procedural_dungeon/` as Node + `.tscn` that quit on success

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** a two-window play of the independent test, **When** both roles exercise home, pocket, building, and skeleton, **Then** both windows agree and the joiner matches the host.

## Notes

Do not claim the story done until headless passes and the play pass is run or explicitly called out as not run. Fantasy exclusion on pocket expire is US-003 and must not fail this harness.
