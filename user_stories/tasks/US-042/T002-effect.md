# T002: Effect — Challenge Rating

**Story**: US-042  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

While `challenge_rating` is owned, apply: **Increase goblin HP.**  
Suggested: +50% max HP (and current scales on apply) for goblins spawned while owned; document whether existing goblins retrofit.

Hook points:
- goblin max HP

## Requirements

- FR-002, FR-003, FR-006, AC1, AC2, AC4

## Acceptance

- **Given** owned, **When** the system under test runs, **Then** the bonus is observable vs a not-owned control.
- **Given** not owned, **When** the same scenario runs, **Then** baseline from referenced stories holds.
