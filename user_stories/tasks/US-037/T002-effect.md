# T002: Effect — Spark

**Story**: US-037  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

While `spark` is owned, apply: **Reduces time between knightling attacks.**  
Suggested: attack interval ×0.7 (or −30%) while owned.

Hook points:
- knightling attack cooldown

## Requirements

- FR-002, FR-003, FR-006, AC1, AC2, AC4

## Acceptance

- **Given** owned, **When** the system under test runs, **Then** the bonus is observable vs a not-owned control.
- **Given** not owned, **When** the same scenario runs, **Then** baseline from referenced stories holds.
