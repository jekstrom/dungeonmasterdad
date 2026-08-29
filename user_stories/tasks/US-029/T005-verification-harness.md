# T005: Verification harness and independent test

**Story**: US-029  
**Status**: Todo  
**Depends on**: T002–T004  
**Parallel**: no

## Goal

Prove once-at-50%, 10s buff, +15% taken, then baseline. Two-window play.

## Files

- `test_harness/procedural_dungeon/us029_sugar_rush_test.gd` (+ `.tscn`)

## Headless checks

- First cross of 50% starts rush once; second hit does not.
- Kill crossing 50% and 0: die, no rush.
- During rush: move/attack faster, damage taken +15%.
- After 10s: baseline.
- Late-join flag/remaining time present.

## Play pass (host + client)

- Chunk HP to half: vibrate, bubbles, faster boss, then 10s later it calms. Peer matches the window.

## Requirements

- Independent Test section of US-029

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** two windows, **When** rush plays, **Then** both agree it is a timed buff, not a forever phase.

## Notes

Do not require Jet, the US-028 fountain, cozy, cube, or fireball.
