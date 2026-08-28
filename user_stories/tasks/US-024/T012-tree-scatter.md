# T012: Scatter trees on eligible interior cells

**Story**: US-024  
**Status**: Done  
**Depends on**: T011  
**Parallel**: no

## Goal

Random existing `TreeDoodad` varieties on a subset of interior outside cells. Configurable density (suggested 4–12% of eligible cells). Host-authoritative.

## Files

- `doodads/tree.tscn` / `doodads/tree.gd` — reuse; `tree_type` 0–9 from `sprites/tree.png`
- Host scatter in the map fill pass
- `playground.tscn` currently has hand-placed trees; match-start scatter should own the set (remove or stop using the authored cluster as the match forest)

## Requirements

- FR-008, AC9
- Eligible cells exclude: dungeon, cliffs, Paper Pusher spawn strip, dungeon exit neighbor cells, and building-blocked cells if any exist at fill time.
- 32×32 frames already exist; no new tree art.

## Acceptance

- **Given** overworld fill, **When** trees are scattered, **Then** each tree sits on an eligible outside cell and density is in the configured range.
- **Given** a dungeon cell, cliff, west spawn strip, or exit-adjacent cell, **When** scatter runs, **Then** no tree is placed there.

## Notes

Harvest is US-006. Buildings still require a clear footprint if a later placement overlaps a tree (story edge case). Replicate tree set in T014.
