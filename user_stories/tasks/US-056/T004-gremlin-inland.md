# T004: Gremlin uses A* (inland cost)

**Story**: US-056  
**Status**: Done  
**Depends on**: T002  
**Owner**: Gameplay

## Goal

Gremlin move-to-pile, carry travel, flee, and wander use the shared path service instead of straight-line + clamp. US-013 inland bias remains: cliff-adjacent walkable cells get a **small extra A\* cost** so inland routes win when both exist. Pickup/carry/drop/flee-priority rules stay US-013. Still walkable-only; never off cliffs.

## Requirements

- FR-006, AC4; US-013 FR-011, FR-012, FR-014

## Acceptance

- **Given** a pile behind a wall, **When** an empty gremlin paths, **Then** it walks around the wall on walkable cells and picks up.
- **Given** inland vs cliff-edge walkable routes, **When** it flees or wanders, **Then** it prefers inland (extra cost), not a second pathfinder.
- **Given** a PP in flee range, **When** AI updates, **Then** flee still overrides pile targeting; the flee route is A\* + inland cost.
