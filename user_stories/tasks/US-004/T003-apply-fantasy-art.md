# T003: Apply Fantasy-element presentation

**Story**: US-004  
**Status**: Todo  
**Depends on**: T002, US-023  
**Parallel**: no

## Goal

When a scheduled drift fires, swap the tile to the **Fantasy-element presentation of the same ground kind and variety index** (US-023 strips). Neutral or Reality → Fantasy. No change to collision, walkability, y-sort, or kind (grass stays grass, dirt stays dirt). Missing strip stays current.

## Files

- US-023 Fantasy-element grass/dirt strips (128×128)
- Outside tile instances / tile-art owner
- Do **not** fall back to a dungeon floor sprite if a variety is missing; stay on current presentation and report a content error

## Requirements

- FR-001, FR-004, AC1, AC4
- Same variety index: do not randomize a different grass/dirt type on convert.
- Reads as grass or dirt with sparkles, blood, and/or vibrant fantasy color rather than paper or grey office yard.
- Missing asset: no crash, no dungeon sprite fallback; keep current outside presentation.

## Acceptance

- **Given** an eligible Reality or Neutral outside tile, **When** its delay fires, **Then** it presents the Fantasy-element of the same kind and variety.
- **Given** Fantasy presentation is showing, **When** a player looks at it, **Then** it reads as sparkle/blood/vibrant grass or dirt, not paper or grey office yard.
- **Given** a conversion, **When** collision/walkability/y-sort/kind are checked, **Then** they are unchanged.
- **Given** a missing Fantasy strip for that variety, **When** the delay fires, **Then** the tile stays on its current presentation.

## Notes

Puff VFX is T005 and must not block this task. Dungeon cells are never passed in (T001).
