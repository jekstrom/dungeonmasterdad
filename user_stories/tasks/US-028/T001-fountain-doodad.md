# T001: Water fountain doodad

**Story**: US-028  
**Status**: Done  
**Depends on**: dungeon generation  
**Parallel**: no

## Goal

Spawn **exactly one** water fountain per match on a reachable walkable cell that is **not** the entrance or exit. Tests may set a **skip-fountain** flag. No splash yet.

## Files

- Suggested scene: `doodads/water_fountain.tscn` (+ script), y-sort feet like `doodads/tree.tscn` (sprite offset, small `StaticBody2D` on wall layer 16 — doodad collision, not a full-cell wall)
- `scripts/procedural_dungeon/` planner (same family as `pickup_spawn_planner.gd` / monster planner) — pick a cell in the Baja Blast boss / exit room; avoid entrance, exit, and the boss tile when another cell in that room is free
- `_globals/dungeon_generation_manager.gd` / layout data — persist fountain cell (or a doodad list) so host spawn and late join agree
- Skip flag on the generation request / harness (same idea as skip-boss)

## Requirements

- FR-001, FR-007, AC1
- Cell MUST be in `walkable_cells`.
- Never place on `entrance_cell` or `exit_cell`.
- Place in the same room as the Baja Blast boss (exit room). Do not stack on the boss tile when another cell in that room is free.
- Seeded from `generation_seed` so the same seed is stable.
- Placeholder art is allowed; generation MUST still succeed.
- Do not implement charge, splash, knockback, or slick here (T002 / T003).
- Do not add a Freeze Wave state to `baja_boss`.

## Acceptance

- **Given** a generated dungeon without skip-fountain, **When** generation completes, **Then** there is exactly one water fountain on a walkable non-entrance, non-exit cell.
- **Given** skip-fountain is set, **When** generation completes, **Then** there is no fountain.
- **Given** two generations with the same seed and knobs, **When** fountain cells are compared, **Then** they match.

## Notes

Periodic splash is T002. Do not use `pickups/bajablast/` as the fountain body.
