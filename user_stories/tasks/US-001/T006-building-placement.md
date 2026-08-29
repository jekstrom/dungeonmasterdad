# T006: Building placement in Reality

**Story**: US-001  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T005

## Goal

Buildings place only when the **entire footprint** is Reality-claimed, on **outside** tiles (US-023), not dungeon cells, and otherwise clear. Host decides success/failure.

## Files

- `_globals/building_manager.gd` — `request_placement` / `is_rect_inside_circle` today; replace circle with claim + outside-tile checks
- Building ghost / HUD placement
- US-023 outside catalog; dungeon cells MUST NOT accept buildings via this path

## Requirements

- FR-007, AC3, AC4, MR-001
- Footprint fully inside Reality (home or pocket).
- On outside tiles only; dungeon rejected.
- If Reality and Fantasy homes overlap with no pocket, overlap rejects placement (FR-010); implementing the Fantasy side of that reject can wait on US-003 if Fantasy claim is not queryable yet — still reject non-fully-Reality footprints now.
- Existing buildings are not auto-destroyed if coverage later fails.

## Acceptance

- **Given** required resources and a clear footprint fully inside Reality on outside tiles, **When** placement is confirmed, **Then** the building is created and enabled.
- **Given** a footprint not fully inside Reality, **When** placement is requested, **Then** the server rejects it and no building is created.
- **Given** a footprint on a dungeon cell, **When** placement is requested, **Then** it is rejected.

## Notes

Paper Factory / Smoke Factory already exist. Do not add new building types. Circle-inside checks must die with T001.
