# T005: Verification harness and independent test

**Story**: US-028  
**Status**: Done  
**Depends on**: T003, T004  
**Parallel**: no

## Goal

Prove fountain spawn → charge → room splash → knockback → dew slick headless, plus two-window play.

## Files

- `test_harness/procedural_dungeon/us028_fountain_slick_test.gd` (+ `.tscn`)

## Headless checks

- Exactly one fountain on a walkable non-entrance, non-exit cell; skip-fountain yields zero.
- Charge before splash.
- DM dummy in the splash: hit + knockback.
- Splash → dew slick with reduced friction; configurable size/duration; expires to baseline traction.
- Open room (no wall): still gets a slick.
- Distinct from Jet stream scene. No Freeze Wave / wave state on `baja_boss`.

## Play pass (host + client)

- Fountain reads as a room hazard. Charge, splash, knockback, slide on dew. Peer matches. Expire restores traction. Boss does not fire this.

## Requirements

- Independent Test section of US-028

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** two windows, **When** the fountain splashes, **Then** both agree on knockback and slick.

## Notes

Do not require Jet, Sugar Rush, cozy, cube, fireball, or a Fantasy pocket.
