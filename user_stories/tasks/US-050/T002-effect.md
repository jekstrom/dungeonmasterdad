# T002: Effect — Everything Burns

**Story**: US-050  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

While `everything_burns` is owned, apply: **Fireball now destroys resources.**  
Suggested: fireball impact destroys (removes) world resource pickups in radius; does not wipe player inventory by default.

Hook points:
- fireball vs resource pickups

## Requirements

- FR-002, FR-003, FR-006, AC1, AC2, AC4

## Acceptance

- **Given** owned, **When** the system under test runs, **Then** the bonus is observable vs a not-owned control.
- **Given** not owned, **When** the same scenario runs, **Then** baseline from referenced stories holds.
