# T003: Room dew slick

**Story**: US-028  
**Status**: Done  
**Depends on**: T002  
**Parallel**: no

## Goal

After a splash, a **Baja dew slick** appears on the fountain room's floor. Players on it have **reduced friction** and **slide**. Duration and size are configurable. Same slide as the old icy sheet; it reads as spilled Mt Dew, not ice and not a Blizzard pocket.

## Files

- Slick area (physics material / move friction on DM and PP) owned by the fountain or a host-spawned floor patch
- Optional `sprites/` dew wash (Baja teal dungeon floor — not `blizzard_overlay.png` zone pocket)

## Requirements

- FR-004, FR-005, AC4
- Spawn the slick when the splash lands. **No wall hit required** (open room still gets a puddle).
- Configurable duration (suggested 4–8s) and size (room walkable cells or a large rect of 128 cells around the fountain).
- Not a Fantasy pocket. Not Bemidji Blizzard slow. Slide is friction, not the 50% move lock from US-017 T005.
- Expire: slick gone, friction baseline. A later splash may refresh or replace the slick; do not stack infinite duration.
- Fountain / boss death MUST NOT leave a **permanent** slick (timer still expires).
- T011 unchanged: slide does not push the DM or a PP out of the dungeon.

## Acceptance

- **Given** a splash, **When** it lands, **Then** a dew slick exists on the fountain room floor for the configured duration.
- **Given** the DM (or a PP) stands on the slick, **When** they move, **Then** they slide (reduced friction).
- **Given** the duration elapses, **When** the slick expires, **Then** traction is baseline.

## Notes

Replication is T004.
