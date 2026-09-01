# T007: Verification harness and independent test

**Story**: US-010  
**Status**: Todo  
**Owner**: QA  
**Depends on**: T003–T006  
**Parallel**: no

## Goal

Prove the independent test headless where possible, and list the two-window play pass.

## Files

- `test_harness/procedural_dungeon/us010_office_max_test.gd` (+ `.tscn`) — quit on success
- Optional shell wrapper matching `us001_run_harness.sh`

## Headless checks

- Legal place: one Office Max with HP (suggested 16); second place rejected.
- One restock press: +`min(10, room)` staples, exactly −1 iron; no paper/wood/smoke spend.
- Empty 20-mag: two presses → full, −2 iron (not one press charging 2).
- Mag with 3 free slots: one press → +3 staples, −1 iron.
- Already full: no-op, no iron spend.
- 0 iron: reject; mag unchanged.
- Out of range / ghost: unchanged.
- Damage to 0: ruined presentation; restock fails; rebuild restores restock + uniqueness.
- Two players: sequential restock; magazines and iron independent.
- Client cannot invent a second Office Max or free-fill.

## Play pass (host + client, two windows)

- Empty mag, restock once: +10 / −1 iron; restock again to full.
- 0 iron: reject. Away from building: fail.
- Second Office Max rejected.
- Destroy: ruined art; peer agrees; rebuild works.

## Requirements

- Independent Test section of US-010

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** a two-window play, **When** both roles restock and destroy, **Then** both windows agree on uniqueness, per-press iron cost, and ruined state.

## Notes

Do not require US-011 goblins, US-027–029, cozy, cube, or fireball.
