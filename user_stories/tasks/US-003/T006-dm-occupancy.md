# T006: DM occupancy in Fantasy-claimed space

**Story**: US-003  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T005

## Goal

The Dungeon Master may enter and move freely inside Fantasy-claimed cells. Zone type does not block them. Normal collision with walls, buildings, and doodads still applies.

## Files

- DM movement / state (`dm/`)
- Fantasy claim API from T001 — query instead of `Area2D` circle overlap

## Requirements

- FR-006, AC3
- DM may enter from outside and remain controllable inside home or pocket.

## Acceptance

- **Given** the Dungeon Master approaches Fantasy-claimed area, **When** they move, **Then** they enter freely and remain controllable inside it.

## Notes

Paper Pusher exclusion is T005. Do not invent a Fantasy-only DM speed buff here (blizzard is US-017).
