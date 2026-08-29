# T001: Carbonated Jet telegraph

**Story**: US-027  
**Status**: Todo  
**Depends on**: US-017 T003  
**Parallel**: no

## Goal

When the boss chooses Carbonated Jet, it **points an arm** (facing pose) and a **linear telegraph** is readable before the stream fires.

## Files

- `monsters/baja_boss.gd` / state machine
- New state (do **not** reuse `monsters/baja_boss_blast.gd` as the jet)
- Telegraph VFX on the dungeon floor (line / thin rect)

## Requirements

- FR-001, AC1
- Suggested tell 0.4–0.8s. Lane matches the upcoming stream.
- Cancel if the boss dies during the tell (no fire).
- Distinct from Freeze Wave’s telegraph (US-028).

## Acceptance

- **Given** the boss chooses Jet, **When** windup starts, **Then** a linear telegraph is visible before any stream exists.
- **Given** the boss dies during the tell, **When** death resolves, **Then** the stream does not fire.

## Notes

Do not spawn the stream here (T002). Do not implement Freeze Wave.
