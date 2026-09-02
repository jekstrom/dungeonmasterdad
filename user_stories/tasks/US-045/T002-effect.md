# T002: Effect — Bemidji Cold

**Story**: US-045  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

While `bemidji_cold` is owned, apply: **Increase duration of blizzard.**  
Suggested: blizzard pocket duration ×1.5 (e.g. 8s→12s) while owned.

Hook points:
- blizzard duration

## Requirements

- FR-002, FR-003, FR-006, AC1, AC2, AC4

## Acceptance

- **Given** owned, **When** the system under test runs, **Then** the bonus is observable vs a not-owned control.
- **Given** not owned, **When** the same scenario runs, **Then** baseline from referenced stories holds.
