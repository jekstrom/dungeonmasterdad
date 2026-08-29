# T001: Spawn Baja Blast boss at dungeon exit

**Story**: US-017  
**Status**: Todo  
**Depends on**: dungeon generation  
**Parallel**: no

## Goal

Spawn **exactly one** Baja Blast boss per match at the dungeon **end/exit**. Not the entrance cell. Tests may set a **skip-boss** flag.

## Files

- `_globals/dungeon_generation_manager.gd` — `get_exit_cell()`, layout `exit_cell` vs entrance
- Monster spawn / `scripts/multiplayer/SpawnManager.gd` (or dungeon monster planner)
- Suggested skip flag on the generation request / harness (same idea as other test skips)

## Requirements

- FR-001, AC1
- James: testing placement is the **exit**, not the start/entrance cell.
- Canonical 24×24 maps use exit `(16,16)` vs start `(2,2)` — spawn at the exit cell (or the exit room), never the entrance cell.
- Skip-boss: generation succeeds with **zero** Baja Blast bosses.
- Do not require the full art sheet to spawn (T002 placeholder).

## Acceptance

- **Given** a generated dungeon without skip-boss, **When** generation completes, **Then** there is exactly one Baja Blast boss at the exit, not the entrance.
- **Given** skip-boss is set, **When** generation completes, **Then** there is no Baja Blast boss.

## Notes

Do not implement combat here (T003). Do not unlock on spawn (T004).
