# T002: Effect — Overcharged

**Story**: US-036  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

While `overcharged` is owned, apply: **Increase distance traveled by knightlings.**  
Suggested: +50% charge/blitz travel distance (or +N cells) while owned.

Hook points:
- knightling move/charge distance

## Requirements

- FR-002, FR-003, FR-006, AC1, AC2, AC4

## Acceptance

- **Given** owned, **When** the system under test runs, **Then** the bonus is observable vs a not-owned control.
- **Given** not owned, **When** the same scenario runs, **Then** baseline from referenced stories holds.
