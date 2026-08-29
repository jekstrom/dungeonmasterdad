# T003: Fantasy ambient sparkles

**Story**: US-026  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T002

## Goal

Subtle, infrequent **sparkles** play on Fantasy-claimed candidates. Not a convert puff. Not Reality dust.

## Files

- Ambient owner from T001
- `sprites/sparks.png` may be reused if it reads; else a small new strip (≤32×32)
- Do **not** loop `sprites/fantasy_drift_puff.png` as the ambience

## Requirements

- FR-002, FR-007, AC2, AC4
- Density stays low (same bar as T002).
- Cosmetic only: no collision, occupancy, or claim change.
- Reality-claimed and unclaimed cells do not get these sparkles.

## Acceptance

- **Given** a nearby Fantasy-claimed cell, **When** a few seconds pass, **Then** infrequent sparkles may appear there.
- **Given** a Reality-claimed or unclaimed cell, **When** time passes, **Then** this task does not emit Fantasy sparkles there.
- **Given** a Fantasy convert puff on a cell, **When** ambience is also playing, **Then** they are distinct VFX.

## Notes

Do not block US-004 T005 on this. Do not apply blizzard slow (US-017).
