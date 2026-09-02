# T002: Effect — Chain Lightning

**Story**: US-038  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

While `chain_lightning` is owned, apply: **Summon 3 knightlings instead of 1.**  
Suggested: one successful knightling summon costs mana once and spawns 3.

Hook points:
- knightling summon count

## Requirements

- FR-002, FR-003, FR-006, AC1, AC2, AC4

## Acceptance

- **Given** owned, **When** the system under test runs, **Then** the bonus is observable vs a not-owned control.
- **Given** not owned, **When** the same scenario runs, **Then** baseline from referenced stories holds.
