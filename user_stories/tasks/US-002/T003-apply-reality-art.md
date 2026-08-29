# T003: Apply Reality-element presentation

**Story**: US-002  
**Status**: Todo  
**Depends on**: T002, US-023  
**Parallel**: no

## Goal

When a scheduled drift fires, swap the tile to the **Reality-element presentation of the same ground kind and variety index** (US-023 strips). Neutral or Fantasy → Reality. No change to collision, walkability, y-sort, or kind (grass stays grass, dirt stays dirt).

## Files

- US-023 Reality-element grass/dirt strips (128×128)
- Outside tile instances / tile-art owner
- Do **not** fall back to a dungeon floor sprite if a variety is missing; stay on current presentation and report a content error

## Requirements

- FR-001, FR-006, AC1, AC6
- Same variety index: do not randomize a different grass/dirt type on convert.
- Fantasy sparkles/blood/saturated ornament gone; mundane lawn/dirt with paper and/or grey office wear.
- Missing asset: no crash, no dungeon sprite fallback.

## Acceptance

- **Given** an eligible Fantasy or Neutral outside tile, **When** its delay fires, **Then** it presents the Reality-element of the same kind and variety.
- **Given** Reality presentation is showing, **When** a player looks at it, **Then** it reads as mundane grass or dirt, not fantasy ornament.
- **Given** a conversion, **When** collision/walkability/y-sort/kind are checked, **Then** they are unchanged.

## Notes

Puff VFX is T005 and must not block this task. Dungeon cells are never passed in (T001).
