# T002: Reality ambient dust

**Story**: US-026  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T003

## Goal

Subtle, infrequent **dust** plays on Reality-claimed candidates. Not a convert puff. Not Fantasy sparkles.

## Files

- Ambient owner from T001
- Optional `sprites/` dust strip (small, ≤32×32) or CPU/GPUParticles2D tinted grey/paper
- Do **not** loop `sprites/reality_drift_puff.png` as the ambience

## Requirements

- FR-001, FR-007, AC1, AC4
- Density stays low (seconds between pops per nearby cell, not a fog).
- Cosmetic only: no collision, occupancy, or claim change.
- Fantasy-claimed and unclaimed cells do not get this dust.

## Acceptance

- **Given** a nearby Reality-claimed cell, **When** a few seconds pass, **Then** infrequent dust may appear there.
- **Given** a Fantasy-claimed or unclaimed cell, **When** time passes, **Then** this task does not emit Reality dust there.
- **Given** a Reality convert puff on a cell, **When** ambience is also playing, **Then** they are distinct VFX.

## Notes

Do not block US-002 T005 on this. Do not invent a second tile catalog.
