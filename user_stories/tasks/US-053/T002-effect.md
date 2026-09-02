# T002: Effect — Grounded

**Story**: US-053  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

While `grounded` is owned, apply: **Paper Pushers can only survive in Fantasy for 3 seconds.**  
Suggested: while owned, a PP whose center is Fantasy-claimed starts a 3s host timer; on expiry they take lethal or forced eject — default: **damage-to-death or kill** after 3s continuous Fantasy claim (timer resets when leaving Fantasy).

Hook points:
- PP Fantasy survival timer

## Requirements

- FR-002, FR-003, FR-006, AC1, AC2, AC4

## Acceptance

- **Given** owned, **When** the system under test runs, **Then** the bonus is observable vs a not-owned control.
- **Given** not owned, **When** the same scenario runs, **Then** baseline from referenced stories holds.
