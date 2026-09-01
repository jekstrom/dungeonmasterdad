# T002: Cell grid and fog paint

**Story**: US-033  
**Status**: Done  
**Depends on**: T001, US-024 map bounds  
**Parallel**: no  
**Owner (after sign)**: Gameplay

## Goal

Paint a fit-to-bounds grid of the cliff **interior**. Cells are fogged or revealed from a reveal-set API (stub empty set OK until T003/T004). No pan/zoom.

## Files

- Mini-map widget from T001
- `MapBounds` / `LevelManager` interior + dungeon cell helpers
- `DungeonGrid.CELL_PX` for aspect

## Requirements

- FR-002, FR-006 (bounds only), AC1, AC9 (fog look)
- Ready to consume `pp_shared_reveal` vs `dm_reveal` by local role.

## Acceptance

- **Given** committed map bounds, **When** the widget paints, **Then** the full interior fits in the panel.
- **Given** an empty reveal set, **When** painted, **Then** all cells read as fog.

## Notes

Debug **`F10`** local full-reveal paint override is **FR-012** (client paint only; do not write host reveal sets). Can land with this paint path or a thin follow-up on the widget.
