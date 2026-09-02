# T002: Effect — Stoke

**Story**: US-048  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

While `stoke` is owned, apply: **Increase fireball radius.**  
Suggested: explosion/impact radius ×1.5 while owned.

Hook points:
- fireball radius

## Requirements

- FR-002, FR-003, FR-006, AC1, AC2, AC4

## Acceptance

- **Given** owned, **When** the system under test runs, **Then** the bonus is observable vs a not-owned control.
- **Given** not owned, **When** the same scenario runs, **Then** baseline from referenced stories holds.
