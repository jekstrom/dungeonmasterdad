# T002: Effect — T-Shirt in December

**Story**: US-046  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

While `tshirt_in_december` is owned, apply: **Add a frost trail behind you (the DM).**  
Suggested: while owned, DM movement leaves a short-lived frost trail (slow and/or Fantasy-tint cells) for N seconds.

Hook points:
- DM frost trail

## Requirements

- FR-002, FR-003, FR-006, AC1, AC2, AC4

## Acceptance

- **Given** owned, **When** the system under test runs, **Then** the bonus is observable vs a not-owned control.
- **Given** not owned, **When** the same scenario runs, **Then** baseline from referenced stories holds.
