# T006: Place mines on eligible overworld cells

**Story**: US-007  
**Status**: Todo  
**Depends on**: T002  
**Parallel**: with T003–T005

## Goal

Each match places **at least one** mine (suggested **2–4**) on harvestable overworld cells: map **interior**, **outside** tiles, **not** dungeon, **not** cliffs, **not** the Paper Pusher west spawn strip, **not** dungeon-exit neighbors, **not** on a tree cell if another cell is free. Prefer cells **outside Fantasy home** at fill time. Host-authoritative, seeded, stable.

## Files

- `_globals/level_manager.gd` — parallel to `rebuild_tree_scatter` / `ScatteredTrees`. e.g. `rebuild_mine_scatter()`, parent `ScatteredMines`, unique names `mine_%d_%d`. Reuse `tree_scatter_eligible_cells()` (or a shared eligible-outside helper) then subtract cells already used by trees. Do not replace tree scatter.
- `doodads/mine.tscn` — instance; `tree_type`-style variety not required.
- Map sync payload (`_tree_sync_items` family) — include a mine list for T008; this task may write host-only spawn and leave late-join fields for T008, but prefer adding `{x,y}` now so T008 only adds depleted/hits.
- `test_harness/procedural_dungeon/us007_mine_placement_test.gd` (+ `.tscn`) — `apply_map_interior` then scatter; count ≥1; every mine on eligible outside cell; none on dungeon/cliff/west strip/exit neighbors; same seed → same cells.

## Requirements

- FR-001
- Configurable count (export / constant). If eligible cells < requested count, place as many as exist (minimum 1 when any eligible cell exists).
- Seeded RNG from interior + dungeon + exit (distinct salt from trees, e.g. `"mines|..."`).
- Host-only spawn (`Lobby.is_network_server()` / `multiplayer.is_server()`). Clients wait for T008 payload.
- Mines must not stack two nodes on one cell by default.

## Acceptance

- **Given** a committed interior with eligible outside cells, **When** mine scatter runs, **Then** there is at least one `MineDoodad` on an eligible cell.
- **Given** a dungeon cell, cliff, west spawn strip, or exit-adjacent cell, **When** scatter runs, **Then** no mine is there.
- **Given** two generations with the same seed and knobs, **When** mine cells are compared, **Then** they match.

## Notes

Fantasy lockouts are T005 (a mine claimed later by Fantasy home growth is still a node; harvest refuses). Harvest gameplay is T003/T004. Do not hand-author mines in `playground.tscn` as the match set.
