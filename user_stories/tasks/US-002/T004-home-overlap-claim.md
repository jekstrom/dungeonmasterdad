# T004: Home overlap claim for drift

**Story**: US-002  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T002

## Goal

Drift claim matches occupancy pockets (pockets override homes; newer pocket wins). If only **homes** overlap and no pocket covers the tile, pick one claim with a **deterministic** rule: **higher covering level wins**; ties keep current art until a winner exists. Only drift toward that claim.

## Files

- Reality claim (US-001) and Fantasy claim (US-003) level values
- Drift eligibility / scheduler (T001–T002) — consume this winner instead of “any Reality-claimed”

## Requirements

- FR-007, AC5, AC8
- Reality pocket over the tile: Reality drift eligible (same as home coverage).
- Fantasy pocket over the tile: not Reality-drift eligible (Fantasy drift is US-004).
- Homes overlap, no pocket: compare Reality Level vs Fantasy Level; higher wins; equal → no drift, keep current art.
- When a Reality pocket expires and Fantasy still claims the tile, it becomes eligible for Fantasy drift (US-004); this task only drops Reality eligibility and cancels pending Reality delays (T002).

## Acceptance

- **Given** a Reality pocket over Fantasy-looking outside tiles, **When** drift is eligible, **Then** those tiles schedule Reality drift the same as home coverage.
- **Given** the pocket expires and Fantasy claims them again, **When** Reality delay was pending, **Then** it is cancelled; they are not Reality-eligible.
- **Given** only homes overlap and Reality Level is higher, **When** eligibility is queried, **Then** the tile may Reality-drift.
- **Given** only homes overlap and levels tie, **When** eligibility is queried, **Then** art stays put.

## Notes

Do not implement Fantasy drift conversion (US-004). Do not change occupancy (US-001 FR-010 still governs players/buildings/skeletons separately).
