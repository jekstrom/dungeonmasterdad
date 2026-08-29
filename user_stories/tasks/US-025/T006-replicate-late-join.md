# T006: Host-authoritative rects and late join

**Story**: US-025  
**Status**: Todo  
**Depends on**: T002, T005  
**Parallel**: no

## Goal

Overlap resolve, shrink, and presentation correction originate on the host. A late joiner receives the **current** home rectangles and current outside-tile art.

## Files

- Zone replication already used by US-001 T008 / US-003 T009
- Tile-art snapshot already used by US-002 T006 / US-004 T006
- Do not send a second copy of the same cells; reuse those snapshots

## Requirements

- FR-006, MR-001, MR-002
- Snapshot includes both live home rects **after** pushback, plus outside presentation that matches claim.
- Pending delays can stay host-only.

## Acceptance

- **Given** the host shrinks a home, **When** peers are in session, **Then** they show the same rects and the same claim.
- **Given** a client joins mid-match, **When** they spawn, **Then** they receive current home rects and current outside art, including cells that were stripped off a stale look.

## Notes

Do not replicate occupancy actors here. Do not implement game over.
