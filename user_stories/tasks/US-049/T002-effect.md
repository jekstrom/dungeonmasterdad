# T002: Effect — Full Cord

**Story**: US-049  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

While `full_cord` is owned, apply: **Reduce cooldown and mana cost of fireball.**  
Suggested: fireball mana cost −5 (min 1) and cast cooldown ×0.7 while owned.

Hook points:
- fireball cost
- fireball cooldown

## Requirements

- FR-002, FR-003, FR-006, AC1, AC2, AC4

## Acceptance

- **Given** owned, **When** the system under test runs, **Then** the bonus is observable vs a not-owned control.
- **Given** not owned, **When** the same scenario runs, **Then** baseline from referenced stories holds.
