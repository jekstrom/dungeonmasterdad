# T003: Vibrate and bubble particles

**Story**: US-029  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T002

## Goal

While Sugar Rush is active, the boss **vibrates** and **bubble particles** emit. Missing particles must not fail the buff.

## Files

- `monsters/baja_boss.tscn` / sprite shake
- Small bubble VFX (local emit OK; Baja fizz, not ice, not Jet syrup)

## Requirements

- FR-005, AC4
- Start with the buff, stop when it ends.
- Cosmetic. Do not change occupancy.

## Acceptance

- **Given** Sugar Rush is active, **When** a player looks, **Then** the boss vibrates and bubbles emit (if art is present).
- **Given** particles fail, **When** T002 is active, **Then** the speed/fragility buff still applies.

## Notes

Do not replicate particle RNG (same idea as US-026). Buff bits are T004.
