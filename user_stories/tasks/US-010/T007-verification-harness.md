# T007: Verification harness and independent test

**Story**: US-010  
**Status**: Todo  
**Owner**: QA  
**Depends on**: T003–T006  
**Parallel**: no

## Goal

Prove the independent test headless where possible, and list the two-window play pass. Do not start until James signs the revised story and Gameplay lands T002–T006.

## Files

- `test_harness/procedural_dungeon/us010_office_max_test.gd` (+ `.tscn`) — quit on success
- Optional shell wrapper matching `us001_run_harness.sh`

## Headless checks

- Legal place: one Office Max with HP (suggested 16); second place rejected.
- Restock with enough iron: mag → max; iron − `ceil(staples_refilled / 10)`; no paper/wood/smoke spend.
- Already full: no-op, no iron spend.
- Not enough iron: reject; mag and iron unchanged.
- Out of range / ghost: unchanged.
- Damage to 0: ruined presentation; restock fails; rebuild restores restock + uniqueness.
- Two players: sequential restock; magazines and iron independent.
- Client cannot invent a second Office Max or remote-fill / free-fill.

## Play pass (host + client, two windows)

- Empty mag, enough iron, restock: HUD full, iron dropped correctly.
- Starve iron: reject. Away from building: fail.
- Second Office Max rejected.
- Destroy: ruined art; peer agrees; rebuild works.

## Requirements

- Independent Test section of US-010

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** a two-window play, **When** both roles restock and destroy, **Then** both windows agree on uniqueness, iron cost, and ruined state.

## Notes

Do not require US-011 goblins, US-027–029, cozy, cube, or fireball.
