# T003: Wall collapse icy sheet

**Story**: US-028  
**Status**: Todo  
**Depends on**: T002  
**Parallel**: no

## Goal

When the wave **hits a wall**, it collapses into a **large icy sheet**. Players on it have **reduced friction** and **slide**. Duration and size are configurable.

## Files

- Dungeon wall collision (existing wall bodies)
- Icy sheet area (physics material / move friction on DM and PP)
- Optional `sprites/` ice wash (blizzard overlay language, dungeon floor — not a US-003 pocket)

## Requirements

- FR-003, FR-004, AC3
- No wall hit: no sheet (open-room default).
- Configurable duration (suggested 4–8s) and size (large rect / several 128 cells along the wall).
- Not a Fantasy pocket. Not Bemidji Blizzard slow. Slide is friction, not 50% move lock from US-017 T005.
- Expire: sheet gone, friction baseline. Boss death must not leave a permanent sheet.

## Acceptance

- **Given** the wave hits a dungeon wall, **When** it collapses, **Then** a large icy sheet exists for the configured duration.
- **Given** the DM (or a PP) stands on the sheet, **When** they move, **Then** they slide (reduced friction).
- **Given** the wave never hits a wall, **When** it ends, **Then** no sheet is created.

## Notes

Replication is T004.
