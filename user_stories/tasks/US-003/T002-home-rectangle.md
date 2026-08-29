# T002: East-anchored home rectangle

**Story**: US-003  
**Status**: Todo  
**Depends on**: T001, US-024 T013  
**Parallel**: with T003

## Goal

The Fantasy **home** is one persistent axis-aligned rectangle, covering or abutting the **east** dungeon AABB, growing with Fantasy Level, clipped to the map interior. Occupancy uses the **live** rectangle, not session-start size.

## Files

- `zones/scripts/zone.gd` — `_place_fantasy_home` already seeds a rect and grows with zone level, then `intersect_interior` (US-024 T013). Keep that clip; replace remaining circle fallback as occupancy.
- Fantasy zone script / playground instance
- `_globals/` DM fantasy level signal — home must listen and rebuild the live rect.
- Map bounds — `intersect_interior(Rect2i) -> Rect2i` (already shipped)
- Dungeon AABB / map interior — home should cover or abut the east dungeon, not float in the west Reality strip

## Requirements

- FR-002, AC (independent test grow), suggested start: covering or abutting the east dungeon AABB
- Growth: expand width and/or height, or each edge, by a configurable amount per Fantasy Level. Clip every rebuild so the home never crosses the cliff ring.
- Generated dungeon is expected to sit inside or become covered as Fantasy Level rises (story assumption). Do not change dungeon generation here.

## Acceptance

- **Given** committed map interior and dungeon AABB, **When** the home is placed, **Then** it is east-anchored (covers or abuts the dungeon), fully inside the interior, and not a circle.
- **Given** Fantasy Level increases, **When** the home rebuilds, **Then** claim uses the new rect immediately and still lies inside the interior.
- **Given** growth that would cross a cliff, **When** clip runs, **Then** the overflow is truncated (US-024 T013).

## Notes

Do not reimplement interior clip; call the existing helper. Pockets are T004. Do not restyle tiles (US-004).
