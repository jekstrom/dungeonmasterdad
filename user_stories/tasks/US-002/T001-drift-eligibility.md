# T001: Drift eligibility

**Story**: US-002  
**Status**: Todo  
**Depends on**: US-001, US-023  
**Parallel**: no

## Goal

A tile is eligible for Reality drift only if it is an **outside** grass/dirt cell, **Reality-claimed** (US-001 home or winning Reality pocket), and **not** inside dungeon bounds. Inclusion is **center-point**.

## Files

- Reality claim API from US-001 (`is_claimed_cell` / world query)
- US-023 outside catalog / dungeon bounds (`DungeonGenerationManager.is_world_position_in_dungeon` or map dungeon AABB)
- New drift eligibility helper (suggested: `scripts/` or `_globals/` tile-art owner): `is_reality_drift_eligible(cell) -> bool`

## Requirements

- FR-002, FR-008, AC1, AC3, AC7, edge: on-edge counts as inside (center-point)
- If the center is in dungeon bounds, the tile is ineligible even if Reality-claimed (occupancy may still apply; art does not).
- Neutral/unclaimed outside tiles are not eligible.
- Do not implement occupancy, pockets, or catalog membership here.

## Acceptance

- **Given** an outside grass/dirt tile whose center is Reality-claimed and outside dungeon bounds, **When** eligibility is queried, **Then** it is eligible.
- **Given** a dungeon floor/wall whose center is Reality-claimed, **When** eligibility is queried, **Then** it is not eligible.
- **Given** an outside tile that is not Reality-claimed, **When** eligibility is queried, **Then** it is not eligible.

## Notes

Pocket geometry is US-001. This task only reads claim. Fantasy drift eligibility after pocket expire is US-004 consuming the same claim change.
