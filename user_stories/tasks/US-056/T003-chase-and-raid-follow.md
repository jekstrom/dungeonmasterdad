# T003: Chase and raid waypoint follow

**Story**: US-056  
**Status**: Done  
**Depends on**: T002  
**Owner**: Gameplay

## Goal

Shared follow helper: path is a polyline. Drop the current cell and reached vertices; skip ahead while the next vertex is visible; steer at the next remaining vertex or the real goal. Never stop on an intermediate cell center. Repath per T002. Host only.

## Requirements

- FR-003, FR-004, FR-005, FR-013, AC1, AC2, AC3, AC12

## Acceptance

- **Given** a goblin/knightling/skeleton and a character behind a wall, **When** aggro chase runs, **Then** the monster walks the hallway around and reaches melee.
- **Given** a goblin and a factory around a corner, **When** it raids, **Then** it paths to stand-off then uses existing strike/retreat.
- **Given** the monster is already in melee range, **When** chase ticks, **Then** it does not request A\*.
- **Given** a client, **When** the host paths, **Then** the client only shows replicated motion.
