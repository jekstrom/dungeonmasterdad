# T002: Effect — Thermostat Lock

**Story**: US-051  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

While `thermostat_lock` is owned, apply: **Paper Pushers lose one inventory slot.**  
Suggested: while owned, each PP max slots −1 (prefer trim static row first); overflow drops as world pickup.

Hook points:
- PP inventory capacity

## Requirements

- FR-002, FR-003, FR-006, AC1, AC2, AC4

## Acceptance

- **Given** owned, **When** the system under test runs, **Then** the bonus is observable vs a not-owned control.
- **Given** not owned, **When** the same scenario runs, **Then** baseline from referenced stories holds.
