# T005: Occupancy in Reality-claimed space

**Story**: US-001  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T006

## Goal

Paper Pushers and the Dungeon Master may path and occupy any walkable Reality-claimed cell. Zone type does not block them. Normal collision with walls, buildings, and doodads still applies.

## Files

- Player and DM movement / state machines (`player/`, `dm/`)
- Reality claim API from T001 — query instead of `Area2D` circle overlap
- Do not invent a new “zone wall”

## Requirements

- FR-005, FR-006, AC1, AC2
- DM may enter Reality from outside and remain controllable inside it.
- Paper Pushers may occupy home or pocket cells.

## Acceptance

- **Given** a Paper Pusher inside Reality (home or pocket), **When** they move, **Then** movement is unrestricted by zone type (walls/buildings/doodads still collide).
- **Given** a Dungeon Master outside Reality, **When** they walk into it, **Then** they enter freely and remain controllable.

## Notes

Paper Pushers walk Fantasy (US-003 T011). Do not push anyone out of Reality here. Skeleton rules are T007.
