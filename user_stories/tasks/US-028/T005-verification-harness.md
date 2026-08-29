# T005: Verification harness and independent test

**Story**: US-028  
**Status**: Todo  
**Depends on**: T003, T004  
**Parallel**: no

## Goal

Prove telegraph → wave → knockback → wall ice sheet headless, plus two-window play.

## Files

- `test_harness/procedural_dungeon/us028_freeze_wave_test.gd` (+ `.tscn`)

## Headless checks

- Telegraph before wave.
- DM dummy in front: hit + knockback.
- Wave vs wall: icy sheet with reduced friction; configurable size/duration.
- No wall: no sheet.
- Distinct from Jet stream scene.

## Play pass (host + client)

- Readable tell, wave, knockback, slide on ice. Peer matches. Expire restores traction.

## Requirements

- Independent Test section of US-028

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** two windows, **When** Freeze Wave plays, **Then** both agree on knockback and sheet.

## Notes

Do not require Jet, Sugar Rush, cozy, cube, fireball, or a Fantasy pocket.
