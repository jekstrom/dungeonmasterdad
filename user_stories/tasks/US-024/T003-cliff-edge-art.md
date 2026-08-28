# T003: Cliff edge and corner sprites

**Story**: US-024  
**Status**: Done  
**Depends on**: none  
**Parallel**: with T001–T002

## Goal

Pixel 3/4 cliff tiles that read as a **drop-off** (dirt/rock/grass lip), meeting Neutral outside grass on the interior side. Not cubicle-stone dungeon walls.

## Files

- `sprites/cliff_edge.png` (or equivalent atlas) — 128×128 frames.
- Import settings consistent with other pixel tiles (`project.godot` canvas default filter is nearest).
- Frames consumed by `level/cliff.tscn` (T002).

## Required frames

| Asset | Size | Notes |
|---|---|---|
| Cliff edge N | 128×128 | North lip; interior is south of this tile |
| Cliff edge E | 128×128 | East lip (right map edge, beside the dungeon) |
| Cliff edge S | 128×128 | South drop-off / face; y-sort from the south |
| Cliff edge W | 128×128 | West lip (Paper Pusher side) |
| Cliff corner NW, NE, SW, SE | 128×128 each | Outer corners of the ring |
| Cliff void / beyond (optional) | 128×128 or empty | Visual past the ring; never walkable |

## Requirements

- Story **Required New Art Assets**
- Offset and cell size match `level/floor.tscn` / `level/wall.tscn`
- Grass on the interior side of a cliff must meet Neutral outside tiles (US-023 Neutral grass)

## Acceptance

- **Given** the eight minimum frames, **When** a rectangular ring is assembled, **Then** edges and outer corners meet without using dungeon wall art.
- **Given** a south cliff, **When** a character approaches from the south, **Then** they draw in front of the lip; from the north the lip overlaps them.

## Notes

Use `game-asset-core` plus `game-tilesets`. Optional void can be a solid color. Trees stay `sprites/tree.png` (T012).
