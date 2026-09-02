# T002: Effect — Random Encounter

**Story**: US-044  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

While `random_encounter` is owned, apply: **Goblins can now lay traps.**  
Suggested: goblins periodically place a simple trap hazard (damage or slow) on overworld cells; host-authoritative.

Hook points:
- goblin trap place
- trap trigger

## Requirements

- FR-002, FR-003, FR-006, AC1, AC2, AC4

## Acceptance

- **Given** owned, **When** the system under test runs, **Then** the bonus is observable vs a not-owned control.
- **Given** not owned, **When** the same scenario runs, **Then** baseline from referenced stories holds.
