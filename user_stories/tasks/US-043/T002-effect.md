# T002: Effect — +1 Swords

**Story**: US-043  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

While `plus_one_swords` is owned, apply: **Increase goblin attack damage.**  
Suggested: +50% goblin melee/ranged damage while owned.

Hook points:
- goblin damage

## Requirements

- FR-002, FR-003, FR-006, AC1, AC2, AC4

## Acceptance

- **Given** owned, **When** the system under test runs, **Then** the bonus is observable vs a not-owned control.
- **Given** not owned, **When** the same scenario runs, **Then** baseline from referenced stories holds.
