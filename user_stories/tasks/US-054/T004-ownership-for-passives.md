# T004: Ownership for passive stories

**Story**: US-054  
**Status**: Todo  
**Depends on**: T002  
**Owner**: Gameplay

## Goal

Successful spends set ownership flags consumed by US-036–053 (and ultimate owned flags `tsb` / `dad_all_powerful` for later effect stories). Late join gets full ownership + SP + FL snapshot. Ownership persists through DM death. Harness force-own remains valid for isolated effect tests without spending SP.

## Requirements

- FR-011, FR-018, FR-024, MR-001, MR-002
- AC18, AC19, AC21

## Acceptance

- **Given** a purchased catalog id, **When** US-036–053 effect code queries ownership, **Then** it reads owned.
- **Given** force-own in a passive harness, **When** used, **Then** it remains allowed without going through SP.
- **Given** a late joiner, **When** they connect, **Then** they receive current SP, both trees’ owned ids, and FL for gate chrome.
- **Given** DM death/respawn, **When** the match continues, **Then** owned nodes remain owned.
