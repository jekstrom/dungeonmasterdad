# T002: Effect — Crib Death

**Story**: US-041  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

While `crib_death` is owned, apply: **Automatically summon 1 gremlin from the dungeon exit every minute; each lives 15 seconds.**  
Suggested: host timer 60s; spawn at overworld exit landing; despawn/kill at 15s lifetime.

Hook points:
- timed exit gremlin spawn

## Requirements

- FR-002, FR-003, FR-006, AC1, AC2, AC4

## Acceptance

- **Given** owned, **When** the system under test runs, **Then** the bonus is observable vs a not-owned control.
- **Given** not owned, **When** the same scenario runs, **Then** baseline from referenced stories holds.
