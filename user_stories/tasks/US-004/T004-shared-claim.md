# T004: Shared claim for drift

**Story**: US-004  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T002

## Goal

Reality and Fantasy drift share **one** claim state per outside tile (FR-006). Pockets override homes. A Fantasy pocket is Fantasy-eligible. A Reality pocket is not. If only **homes** overlap and no pocket covers the tile, **higher covering level wins**; ties keep current art. After Fantasy claim is gone and Reality still claims, cells become eligible for Reality drift (US-002).

## Files

- Shared claim winner from US-002 T004 (consume it; do not fork a second rule)
- Fantasy claim (US-003) and Reality claim (US-001) level values
- Drift eligibility / scheduler (T001–T002)

## Requirements

- FR-006, AC5, AC8
- Fantasy pocket over the tile: Fantasy drift eligible (same as home coverage).
- Reality pocket over the tile: not Fantasy-drift eligible (Reality drift is US-002).
- Homes overlap, no pocket: compare Fantasy Level vs Reality Level; higher wins; equal → no drift, keep current art.
- When a Fantasy pocket expires and Reality still claims the tile, it becomes eligible for Reality drift (US-002); this task only drops Fantasy eligibility and cancels pending Fantasy delays (T002).

## Acceptance

- **Given** a Fantasy pocket over Reality-looking outside tiles, **When** drift is eligible, **Then** those tiles schedule Fantasy drift the same as home coverage.
- **Given** the pocket expires and Reality claims them again, **When** Fantasy delay was pending, **Then** it is cancelled; they are not Fantasy-eligible and become eligible for Reality drift (US-002).
- **Given** only homes overlap and Fantasy Level is higher, **When** eligibility is queried, **Then** the tile may Fantasy-drift.
- **Given** only homes overlap and levels tie, **When** eligibility is queried, **Then** art stays put.

## Notes

Do not implement Reality drift conversion (US-002). Do not change occupancy (US-003 still governs players/buildings/skeletons separately).
