# T002: Effect — Minions

**Story**: US-039  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

While `minions` is owned, apply: **Gremlins can carry 1 more item.**  
Suggested: carry capacity 1→2 while owned.

Hook points:
- gremlin carry slots

## Requirements

- FR-002, FR-003, FR-006, AC1, AC2, AC4

## Acceptance

- **Given** owned, **When** the system under test runs, **Then** the bonus is observable vs a not-owned control.
- **Given** not owned, **When** the same scenario runs, **Then** baseline from referenced stories holds.
