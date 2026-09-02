# T004: Ownership for passive stories

**Story**: US-054  
**Status**: Todo  
**Depends on**: T002  
**Owner**: Gameplay

## Goal

Successful spends set ownership flags consumed by US-036–053 (and ultimate owned flags for later effect stories). Late join gets full ownership + SP snapshot.

## Requirements

- FR-011, MR-001, MR-002, AC12

## Acceptance

- **Given** a purchased passive, **When** US-036–053 effect code queries ownership, **Then** it reads owned.
- **Given** force-own in a passive harness, **When** used, **Then** it remains allowed for isolated effect tests without going through SP.
