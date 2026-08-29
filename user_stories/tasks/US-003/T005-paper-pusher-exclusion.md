# T005: Paper Pusher exclusion

**Story**: US-003  
**Status**: Revoked  
**Replaced by**: [T011](T011-paper-pusher-walk.md)  
**Depends on**: T001  
**Parallel**: with T006

## Goal

**Revoked.** James: Paper Pushers can exist and walk in and out of Fantasy zones. Do **not** implement a wall or push-out. If this task already shipped, T011 removes it.

Original intent (do not build): Paper Pushers cannot enter Fantasy-claimed space; host pushes them out if already inside.

## Files

None. See T011.

## Requirements

- Do not implement FR-005/FR-009 as they were originally written.
- Current occupancy: FR-005 / FR-009 as amended in US-003.md (walk, no wall, no push-out).

## Acceptance

- **Given** this task, **When** work is scheduled, **Then** skip it and do T011 instead.

## Notes

DM occupancy is T006. Building reject is T007. Skeleton allow is T008. Those stand.
