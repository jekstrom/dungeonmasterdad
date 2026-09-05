# T005: Maze infill of leftover bounds

**Story**: US-057  
**Status**: Todo  
**Depends on**: T003  
**Owner**: Gameplay

## Goal

Unused cells inside generation bounds should be able to become **maze corridors or alcoves**, not a thin L of rooms in a sea of solid wall that still reads as a long dungeon.

Grow or carve infill from existing hallways/rooms with the same 4-connected maze rules. Dead-end pockets stay valid; they MUST NOT be the only extra structure (today: `clamp(mid_count, 1, 3)` pockets).

Respect compactness: infill should **fill toward a compact blob**, not stretch the AABB into a sausage.

## Files

- `scripts/procedural_dungeon/maze_infill_generator.gd`
- `scripts/procedural_dungeon/layout_composer.gd`

## Requirements

- FR-007, AC1, AC5

## Acceptance

- **Given** square bounds with scattered rooms, **When** infill runs, **Then** leftover area can contain extra corridors/dead-ends beyond three pockets.
- **Given** compactness retry, **When** infill would stretch aspect above the cap, **Then** that attempt fails or infill is clipped.
