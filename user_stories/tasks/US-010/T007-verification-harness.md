# T007: Verification harness and independent test

**Story**: US-010  
**Status**: Todo  
**Owner**: QA  
**Depends on**: T003–T006  
**Parallel**: no

## Goal

Prove the independent test headless where possible, and list the two-window play pass. Do not start this until James signs the story and Gameplay lands T002–T006.

## Files

- `test_harness/procedural_dungeon/us010_office_max_test.gd` (+ `.tscn`) — Node script that quits on success (US-001 / US-005 pattern)
- Optional shell wrapper matching `us001_run_harness.sh`

## Headless checks

- Legal place: one Office Max; iron required as designed.
- Second place while enabled: rejected.
- Non-full mag + in range interact: mag → max; no paper/wood/iron/smoke spent for refill.
- Already full: no-op.
- Out of range: mag unchanged.
- Ghost: not restockable.
- Destroy/disable: restock fails; rebuild restores restock and uniqueness allows one again.
- Two players: sequential restock; magazines independent.
- Client cannot invent a second Office Max or remote-fill another mag.

## Play pass (host + client, two windows)

- Empty mag, walk to Office Max, restock, HUD full.
- Restock away from it: fails.
- Second Office Max placement rejected.
- Peer sees one building; each player can refill their own mag.

## Requirements

- Independent Test section of US-010
- Testing skill: new tests under `test_harness/procedural_dungeon/` as Node + `.tscn` that quit on success

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** a two-window play of the independent test, **When** both roles restock, **Then** both windows agree on uniqueness and per-player magazines.

## Notes

Do not require US-011 goblins, US-027–029 Baja work, cozy, cube, or fireball. Do not claim the story done until James has signed and this pass is run or explicitly called out as not run.
