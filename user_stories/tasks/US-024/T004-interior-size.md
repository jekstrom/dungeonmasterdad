# T004: Interior size ≥ 4× dungeon AABB

**Story**: US-024  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: no (blocks T005–T006)

## Goal

Once the generated dungeon AABB is known, the map interior cell count is at least **4×** that AABB’s area. Default: interior `2·Wd × 2·Hd` for dungeon `Wd × Hd`.

## Files

- `scripts/procedural_dungeon/map_bounds.gd` — `interior_from_dungeon_aabb(dungeon: Rect2i) -> Rect2i`
- `_globals/dungeon_generation_manager.gd` — read committed `_dungeon_cell_bounds` / layout AABB
- `scripts/procedural_dungeon/dungeon_generator.gd` — `bounds_size` still drives dungeon generation; interior is derived, not the generator knob

## Requirements

- FR-002
- Suggested default: dungeon flush east (T005) and vertically centered; if `Hd` equals interior height, flush north is allowed.
- If the dungeon AABB is taller than the planned interior height: grow interior height to fit the dungeon plus **at least one cell** of padding from the north and south cliffs, then widen if needed so area stays ≥ 4×.

## Acceptance

- **Given** a dungeon AABB of `Wd × Hd` cells, **When** interior is measured, **Then** interior cell count ≥ `4 * Wd * Hd` (cliff ring excluded).
- **Given** a dungeon taller than the first-pass interior, **When** bounds are committed, **Then** north/south cliffs do not overlap dungeon cells and the 4× rule still holds.

## Notes

Cliff ring is **outside** the interior rect (T006). Default generator `bounds_size` 24×24 implies at least 48×48 interior in the 2×2 default. Playground currently uses other `bounds_size` values; the policy is relative to the **committed** dungeon AABB, not a hardcoded 48.
