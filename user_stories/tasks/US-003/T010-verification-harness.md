# T010: Verification harness and independent test

**Story**: US-003  
**Status**: Todo  
**Depends on**: T005–T009  
**Parallel**: no

## Goal

Prove the independent test headless where possible, and list the two-window play pass.

## Files

- `test_harness/procedural_dungeon/us003_fantasy_claim_test.gd` (+ `.tscn`) — Node script that quits on success (same pattern as US-001 T009 / US-024 T015)
- Optional shell wrapper matching `us024_run_harness.sh`

## Headless checks

- Claim API ignores any leftover circle; home-only cells match the east-anchored rect and sit inside the interior.
- Home rebuilds with Fantasy Level and stays inside map interior.
- Pocket create clips to interior; overlap prefers the newer pocket; expire drops that rect from claim.
- Paper Pusher cannot occupy a Fantasy-claimed cell; a PP placed inside is displaced to non-Fantasy walkable (or Reality spawn) and remains alive.
- DM can occupy Fantasy-claimed cells.
- Building footprint intersecting Fantasy rejects; existing building is not destroyed when covered.
- Skeleton on Fantasy-only claim is allowed; skeleton on Reality-claimed (pocket or FR-010 home overlap) is banned.

## Play pass (host + client, two windows)

- Paper Pusher stops at the Fantasy home edge; DM walks through.
- Illegal building footprint touching Fantasy does not place.
- Skeleton exists in Fantasy home (no Reality pocket); vanishes if a Reality pocket covers it.
- Fantasy pocket over Reality home: PP pushed out, distinct overlay; on expire, Reality home rules return and PP may re-enter.
- Late join: same home, pockets, occupancy; client log clean.

## Requirements

- Independent Test section of US-003
- Testing skill: new tests under `test_harness/procedural_dungeon/` as Node + `.tscn` that quit on success

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** a two-window play of the independent test, **When** both roles exercise home, pocket, building, skeleton, and PP push, **Then** both windows agree and the joiner matches the host.

## Notes

Do not claim the story done until headless passes and the play pass is run or explicitly called out as not run. Blizzard slow/unlock must not be required to pass this harness (use the pocket create API directly).
