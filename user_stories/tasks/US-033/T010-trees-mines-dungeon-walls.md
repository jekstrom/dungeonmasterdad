# T010: Trees, mines, and dungeon walls on revealed cells

**Story**: US-033  
**Status**: Done  
**Depends on**: T002 (grid); T003 or T004 for fog gate; builds on T005 paint pass  
**Parallel**: with T008 pip art  
**Owner**: Gameplay

## Goal

On **revealed** cells only, paint **living tree** pips (US-024 `scattered_trees` + US-032 exit-forest trees; **stumps off by default**), **mine** pips (US-007), and **dungeon wall** cells as a **dark wall-tint** silhouette. Fogged cells hide all three. Do **not** change `pp_shared_reveal` / `dm_reveal` rules.

## Files

- Mini-map paint pass (T005 path)
- `scattered_trees` / exit-forest tree groups (`TreeDoodad`, `is_stump`)
- Scattered mines / mine doodads
- Generated dungeon wall tiles / wall footprint (`level/wall.tscn`, dungeon wall set from generation)
- Art pips/tint from T008 when ready (colored rects OK first)

## Requirements

- FR-011, AC9 (extended), AC12
- Wall tint = dark wall-tint cell fill (not a full art wall sprite required for v1)
- Tree/mine = small pips

## Acceptance

- **Given** a revealed cell with a living scattered or exit-forest tree, **When** painted, **Then** a tree pip shows; a stump does not (v1 default); the same tree on a fogged cell does not.
- **Given** a revealed cell with a mine, **When** painted, **Then** a mine pip shows; fogged = hidden.
- **Given** a revealed dungeon wall footprint cell, **When** painted, **Then** it uses dark wall-tint; an unrevealed wall cell stays fogged with no wall silhouette leak.
- **Given** only this content landing, **When** reveal sets are inspected, **Then** PP shared and DM private sets are unchanged in rules/merger.

## Notes

Scope add from James while Signed (PR #14 tip `5c1da01`). T005 zones/buildings stay Done; this extends world content markers.
