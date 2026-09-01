# T002: Dense TreeDoodad placement in pocket

**Story**: US-032  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T003

## Goal

Fill the exit forest pocket with a **dense** set of `TreeDoodad` instances (`doodads/tree.tscn`). Density must read as woods (well above US-024 sparse ~4–12%). Skip egress-clear cells. No dungeon overlap.

## Files

- `doodads/tree.tscn` / `doodads/tree.gd` (`TreeDoodad`)
- `_globals/level_manager.gd` — `rebuild_tree_scatter()` pattern (separate forest parent/group suggested, e.g. `ExitForestTrees`)
- Existing `sprites/tree.png` frames

## Requirements

- FR-001, FR-002, FR-006, AC1, AC2
- Host places; use existing tree_type variety.
- Do not implement Skill Tree here (T003).
- Do not change harvest rules (US-006).

## Acceptance

- **Given** a non-empty pocket, **When** forest place runs, **Then** most eligible non-egress pocket cells get a tree (tunable high density).
- **Given** any placed forest tree, **When** its cell is checked, **Then** it is outside the dungeon footprint.
- **Given** egress-clear cells, **When** place finishes, **Then** they have no forest tree.

## Notes

Keep forest trees in a distinct group from `scattered_trees` so US-024 rebuilds do not wipe or double-manage them carelessly.
