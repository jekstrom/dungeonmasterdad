# T005: Sparse scatter excludes forest pocket

**Story**: US-032  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T002

## Goal

US-024 sparse `rebuild_tree_scatter` must treat the **entire exit forest pocket** (not only today’s exit + 4-neighbors) as blocked so sparse trees never land inside the dense forest. Sparse density elsewhere unchanged.

## Files

- `_globals/level_manager.gd` — `tree_scatter_eligible_cells()`, `_tree_scatter_blocked_cells()`, `strip_scattered_trees_from_blocked_cells()`
- US-024 T012 contract

## Requirements

- FR-007, AC6
- Expand or replace the exit-neighbor block with the pocket from T001.
- Do not delete the sparse system.

## Acceptance

- **Given** pocket cells, **When** sparse eligible cells are listed, **Then** no pocket cell is eligible.
- **Given** interior outside cells outside the pocket, **When** sparse runs, **Then** they remain eligible under US-024 rules.

## Notes

Mine scatter already prefers non-tree cells; once forest trees exist, mines should keep avoiding them when possible (edge case in story).
