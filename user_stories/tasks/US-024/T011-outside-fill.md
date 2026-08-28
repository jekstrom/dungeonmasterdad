# T011: Fill interior with outside grass/dirt

**Story**: US-024  
**Status**: Done  
**Depends on**: T005; **US-023** for the real catalog  
**Parallel**: with T013

## Goal

Every interior cell that is not a dungeon cell is an **outside** tile (US-023): random grass or dirt, Neutral presentation until a zone claims it. No outside tile on dungeon or cliff cells.

## Files

- Outside catalog from US-023 (when present)
- Fill pass on the host after dungeon commit (level manager or map fill owner)
- Strip outside tiles from dungeon cells if any were pre-placed (`scripts/multiplayer_spawner.gd` generated-tile replace is the model)

## Requirements

- FR-007, AC8, FR-010
- Variety chosen randomly per cell or per coherent patch.
- Neutral until US-002 / US-004 drift.

## Acceptance

- **Given** a cell in the map interior that is not dungeon and not cliff, **When** the map is filled, **Then** it is outside grass or dirt.
- **Given** a dungeon or cliff cell, **When** fill runs, **Then** it does not receive an outside tile.

## Notes

If US-023 is not merged, use a Neutral outside placeholder scene that is **not** `level/floor.tscn`. Do not paint dungeon stone as lawn. Dungeon generation must still strip outside tiles from dungeon cells (US-023 FR-005).
