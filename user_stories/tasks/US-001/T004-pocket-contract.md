# T004: Reality pocket contract

**Story**: US-001  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: no

## Goal

Effects may create **temporary Reality rectangles** with origin, size, and duration. No named Paper Pusher abilities in this task — only the contract those abilities will call.

## Files

- Pocket set on the Reality claim owner (T001)
- `zones/scripts/zone.gd` — `clip_pocket_rect` already truncates to interior; use it
- SignalBus — pocket created / expired
- Suggested default: tile-aligned `Rect2i`, duration 6–12s (configurable on the effect)

## Requirements

- FR-003, FR-004, AC8, AC9
- Degenerate or zero-size rectangle: treat as no pocket.
- While live, every point inside is Reality for movement, building, skeletons, even over Fantasy home ground.
- If two pockets overlap, the **newer** pocket wins.
- On expire: the rectangle is no longer Reality by itself; remaining home/pocket coverage is re-evaluated. Existing buildings are not auto-destroyed.

## Acceptance

- **Given** a pocket create with origin/size/duration, **When** it resolves, **Then** the rect is clipped to the interior and claim inside it is Reality for the duration.
- **Given** two overlapping pockets, **When** claim is queried in the overlap, **Then** the newer pocket wins.
- **Given** a pocket expires, **When** the next occupancy pass runs, **Then** that rect is not Reality unless home or another pocket still covers it.

## Notes

Do not name or implement a specific ability. US-003 displacement on expire (Paper Pushers left in Fantasy) is out of scope; this task only restores Reality claim.
