# T002: Scatter rooms in bounds

**Story**: US-057  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

Stop placing mid rooms on `DungeonGrid.carve_l(start, exit)`.

`RoomGraphGenerator.generate_room_backbone` (or successor) MUST:

- Place start and exit rooms at the requested (or auto) centers.
- Place mid rooms by sampling **in-bounds** cells with existing radius, `MIN_ROOM_CELLS`, and center separation.
- Build a **room graph** (start–mids–exit connected, optional extra edges) without requiring centers to lie on an L.

Graph edges mean “carve a hallway between these rooms,” not “L-carve now.”

## Files

- `scripts/procedural_dungeon/room_graph_generator.gd`
- `scripts/procedural_dungeon/generation/dungeon_layout_builder.gd`

## Requirements

- FR-001, FR-002, AC1, AC2

## Acceptance

- **Given** square bounds and start/exit not on a long L, **When** rooms are placed, **Then** mid rooms exist off that L when space allows.
- **Given** room_count, **When** generation succeeds, **Then** start + exit + mids still match the count contract (3–8 rooms).
