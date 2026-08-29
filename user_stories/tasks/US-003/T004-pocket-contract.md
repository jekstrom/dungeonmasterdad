# T004: Fantasy pocket contract

**Story**: US-003  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: no

## Goal

Effects may create **temporary Fantasy rectangles** with origin, size, and duration. Bemidji Blizzard (US-017) **will call this contract**. No blizzard slow, unlock, or numbers in this task.

## Files

- Pocket set on the Fantasy claim owner (T001)
- `zones/scripts/zone.gd` — `clip_pocket_rect` already truncates to interior; use it
- SignalBus — pocket created / expired
- Suggested default: tile-aligned `Rect2i`, duration on the effect

## Requirements

- FR-003, FR-004, AC8, AC9
- Degenerate or zero-size rectangle: treat as no pocket.
- While live, every point inside is Fantasy for movement, building, skeletons, even over Reality home ground.
- If two pockets overlap, the **newer** pocket wins (same rule as US-001 FR-004).
- On expire: the rectangle is no longer Fantasy by itself; remaining home/pocket coverage is re-evaluated. Existing buildings are not auto-destroyed. Paper Pushers already there stay (T011).

## Acceptance

- **Given** a pocket create with origin/size/duration, **When** it resolves, **Then** the rect is clipped to the interior and claim inside it is Fantasy for the duration.
- **Given** two overlapping pockets, **When** claim is queried in the overlap, **Then** the newer pocket wins.
- **Given** a pocket expires, **When** the next occupancy pass runs, **Then** that rect is not Fantasy unless home or another pocket still covers it.

## Notes

Do not implement blizzard slow or unlock (US-017). Leave a single create API blizzard can call. Reality pocket override of Fantasy is US-001 / T008, not a second pocket type here. Do not push Paper Pushers on create or expire.
