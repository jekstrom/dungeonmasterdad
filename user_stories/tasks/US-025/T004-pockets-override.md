# T004: Pockets still override homes

**Story**: US-025  
**Status**: Todo  
**Depends on**: T001, US-001 T004, US-003 T004  
**Parallel**: no

## Goal

Live pockets still override homes for occupancy and drift. When a pocket expires, remaining claim uses the **no-overlap home rects**, not the old overlapping FR-010.

## Files

- `zones/scripts/reality_claim.gd` / `fantasy_claim.gd` — pocket vs home
- `scripts/procedural_dungeon/zone_drift_claim.gd` — pocket override already exists; keep it
- Pocket expire listeners used by US-002 T002 / US-004 T002

## Requirements

- FR-004, AC4
- Newer pocket still wins when pockets overlap (US-001 FR-004 / US-003 FR-004).
- A Fantasy pocket over Reality home is Fantasy-claimed while live (occupancy + drift). A Reality pocket over Fantasy home is Reality-claimed while live.
- Creating or expiring a pocket MUST NOT shrink or grow a home rect. Homes stay the exclusive rects from T002/T003.
- After expire, cells fall back to whichever **single** home covers them, or unclaimed.

## Acceptance

- **Given** a Fantasy pocket over Reality-home cells, **When** the pocket is live, **Then** those cells are Fantasy-claimed even though the Reality home rect still exists underneath (and does not overlap the Fantasy **home**).
- **Given** that pocket expires, **When** claim is re-evaluated, **Then** the cells are Reality-home again if the Reality rect still covers them, and the two home rects are still disjoint.
- **Given** a pocket create/expire, **When** home rects are inspected, **Then** they did not change because of the pocket.

## Notes

Do not implement blizzard slow (US-017). Do not change Paper Pusher exclusion / skeleton ban beyond using the live claim.
