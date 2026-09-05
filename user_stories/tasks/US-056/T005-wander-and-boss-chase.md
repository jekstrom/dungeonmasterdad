# T005: Wander and Baja boss chase

**Story**: US-056  
**Status**: Done  
**Depends on**: T002  
**Owner**: Gameplay

## Goal

`EnemyStateWander` MUST NOT step into walls/cliffs/void: if the random cardinal is blocked, pick another walkable dir or A\* to a nearby wander cell. Baja Blast boss **chase** uses the same follow helper as T003. Carbonated jet / jet state stay straight projectiles.

## Requirements

- FR-007, AC5, AC6

## Acceptance

- **Given** a wandering goblin/skeleton/knightling facing a wall, **When** wander ticks, **Then** it does not enter the wall cell.
- **Given** the Baja Blast boss chasing the DM around a wall, **When** in chase, **Then** it walks around; a jet still fires in a line.
