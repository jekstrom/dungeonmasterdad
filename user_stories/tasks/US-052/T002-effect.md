# T002: Effect — Dad Reflexes

**Story**: US-052  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

While `dad_reflexes` is owned, apply: **Gain dash ability.**  
Suggested: DM dash on a dedicated input with cooldown; host-authoritative displacement; short i-frames optional default off.

Hook points:
- DM dash move
- dash input/cooldown

## Requirements

- FR-002, FR-003, FR-006, AC1, AC2, AC4

## Acceptance

- **Given** owned, **When** the system under test runs, **Then** the bonus is observable vs a not-owned control.
- **Given** not owned, **When** the same scenario runs, **Then** baseline from referenced stories holds.
