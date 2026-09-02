# T002: Effect — Put a Sweater On

**Story**: US-047  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

While `put_a_sweater_on` is owned, apply: **Blizzard now does damage.**  
Suggested: PPs (and optionally buildings) inside live blizzard take periodic host damage while owned.

Hook points:
- blizzard damage tick

## Requirements

- FR-002, FR-003, FR-006, AC1, AC2, AC4

## Acceptance

- **Given** owned, **When** the system under test runs, **Then** the bonus is observable vs a not-owned control.
- **Given** not owned, **When** the same scenario runs, **Then** baseline from referenced stories holds.
