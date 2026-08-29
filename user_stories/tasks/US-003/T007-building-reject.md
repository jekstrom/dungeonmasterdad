# T007: Building reject on Fantasy intersection

**Story**: US-003  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: no

## Goal

Building placement is rejected if **any** part of the footprint intersects Fantasy-claimed area. Host decides. Existing buildings are not auto-destroyed when Fantasy later covers them.

## Files

- `_globals/building_manager.gd` — placement already Reality-gated in US-001 T006; add Fantasy intersection reject
- Building ghost / HUD should show illegal if the footprint touches Fantasy

## Requirements

- FR-007, FR-010, AC4
- Reject if any cell of the footprint is Fantasy-claimed (home or pocket).
- Homes overlap with no pocket: still reject (FR-010).
- Existing buildings remain; they cannot be repaired/expanded into Fantasy; production is not stopped by occupancy alone (blizzard slow is US-017).

## Acceptance

- **Given** a footprint that intersects Fantasy-claimed area, **When** placement is requested, **Then** the server rejects it and no building is created.
- **Given** Fantasy later covers an existing factory, **When** occupancy updates, **Then** the factory is not destroyed.

## Notes

Do not add new building types. Reality full-footprint rule stays US-001 T006; this task is the Fantasy intersection reject.
