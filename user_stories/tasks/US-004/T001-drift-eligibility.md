# T001: Drift eligibility

**Story**: US-004  
**Status**: Todo  
**Depends on**: US-003, US-002 T004, US-023  
**Parallel**: no

## Goal

A tile is eligible for Fantasy drift only if it is an **outside** grass/dirt cell, **Fantasy-claimed** (US-003 home or winning Fantasy pocket), **not** inside dungeon bounds, and **not** Reality-claimed. Inclusion is **center-point**. Use the **same claim winner** as US-002 (US-004 FR-006 / US-002 T004).

## Files

- Fantasy claim API from US-003 (`is_claimed_cell` / world query)
- Shared claim winner from US-002 T004 (do not invent a second winner)
- US-023 outside catalog / dungeon bounds (`DungeonGenerationManager.is_world_position_in_dungeon` or map dungeon AABB)
- New drift eligibility helper (suggested: `scripts/` or `_globals/` tile-art owner): `is_fantasy_drift_eligible(cell) -> bool`

## Requirements

- FR-002, FR-006, FR-007, AC1, AC3, AC7, edge: on-edge counts as inside (center-point)
- If the center is in dungeon bounds, the tile is ineligible even if Fantasy-claimed (occupancy may still apply; art does not).
- Reality-claimed tiles (winning Reality pocket, or home winner) are not Fantasy-eligible.
- Neutral/unclaimed outside tiles are not eligible.
- Do not implement occupancy, pockets, or catalog membership here.

## Acceptance

- **Given** an outside grass/dirt tile whose center is Fantasy-claimed, outside dungeon bounds, and not Reality-claimed, **When** eligibility is queried, **Then** it is eligible.
- **Given** a dungeon floor/wall whose center is Fantasy-claimed, **When** eligibility is queried, **Then** it is not eligible.
- **Given** an outside tile that is Reality-claimed or not Fantasy-claimed, **When** eligibility is queried, **Then** it is not eligible.

## Notes

Pocket geometry is US-003. This task only reads the shared claim. Reality drift eligibility after Fantasy pocket expire is US-002 consuming the same claim change.
