# T002: Effect — Blind one-legged monkeys

**Story**: US-040  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

While `blind_one_legged_monkeys` is owned, apply: **Gremlins turn invisible.**  
Suggested: living gremlins use stealth/invisibility (still collidable or hit-scannable — default: invisible to PP view, still damagable).

Hook points:
- gremlin visibility

## Requirements

- FR-002, FR-003, FR-006, AC1, AC2, AC4

## Acceptance

- **Given** owned, **When** the system under test runs, **Then** the bonus is observable vs a not-owned control.
- **Given** not owned, **When** the same scenario runs, **Then** baseline from referenced stories holds.
