# T011: Paper Pushers walk Fantasy (T005 revoked)

**Story**: US-003  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T006  
**Addendum**: James — Paper Pushers can exist and walk in and out of Fantasy zones. T005 exclusion/push-out is revoked.

## Goal

Paper Pushers walk Fantasy **home** and **pockets**. No zone wall. No push-out. If T005 already shipped, remove the barrier and the occupancy shove.

## Files

- Player movement / physics (`player/`)
- Fantasy claim API from T001 — query is fine; do not use it to block or displace PP
- Any host occupancy pass that shoves PP out of Fantasy (T005) — delete it
- Client prediction that stops PP at the Fantasy edge — delete it

## Requirements

- FR-005, FR-009, AC1, AC2
- PP may enter from outside, remain when home grows or a pocket appears, and leave freely.
- Normal collision with walls, buildings, doodads, and map cliffs still applies.
- DM occupancy (T006), building reject (T007), skeleton allow (T008) unchanged.
- Do not implement game over.

## Acceptance

- **Given** a Paper Pusher outside Fantasy-claimed area, **When** they walk into Fantasy home or a live pocket, **Then** they enter and remain.
- **Given** a Paper Pusher already inside Fantasy, **When** physics runs, **Then** they are not pushed out.
- **Given** T005 wall or displacement still exists, **When** this task lands, **Then** it is gone.

## Notes

Do not define combat reach (US-005). Do not apply blizzard slow (US-017). Home exclusivity is US-025, not a PP wall.
