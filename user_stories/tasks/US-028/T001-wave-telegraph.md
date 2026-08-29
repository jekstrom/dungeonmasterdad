# T001: Freeze Wave telegraph

**Story**: US-028  
**Status**: Todo  
**Depends on**: US-017 T003  
**Parallel**: no

## Goal

When the boss chooses Freeze Wave, a telegraph is readable before the wave fires. Distinct from Jet’s thin linear lane.

## Files

- `monsters/baja_boss.gd` / new freeze-wave state (not Jet, not `baja_boss_blast.gd`)
- Telegraph VFX (wider lane / arc)

## Requirements

- FR-001, AC1, AC4
- Cancel on death during the tell.

## Acceptance

- **Given** Freeze Wave is chosen, **When** windup starts, **Then** a telegraph is visible before the wave exists.
- **Given** Jet’s telegraph, **When** Freeze Wave plays, **Then** the tells are visually distinct.

## Notes

Wave body is T002.
