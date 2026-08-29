# T002: West-anchored home rectangle

**Story**: US-001  
**Status**: Todo  
**Depends on**: T001, US-024 T013  
**Parallel**: with T003

## Goal

The Reality **home** is one persistent axis-aligned rectangle, anchored on the **west** interior edge (Paper Pusher spawn), growing with Reality Level, clipped to the map interior. Occupancy uses the **live** rectangle, not session-start size.

## Files

- `zones/scripts/zone.gd` — `_place_reality_home` already west-strips `interior` and calls `intersect_interior` (US-024 T013). Keep that clip; replace remaining circle fallback (`_apply_circle_radius`) as occupancy.
- `zones/RealityZone.gd`
- `_globals/player_manager.gd` — Reality Level signal already exists; home must listen and rebuild the live rect.
- Map bounds — `intersect_interior(Rect2i) -> Rect2i` (already shipped in US-024 T013)

## Requirements

- FR-002, AC7, suggested start: west interior edge
- Growth: expand width and/or height, or each edge, by a configurable amount per Reality Level. Clip every rebuild so the home never crosses the cliff ring.
- If Reality Level can drop, the home may shrink; existing buildings are not auto-destroyed (edge case in the story).

## Acceptance

- **Given** committed map interior, **When** the home is placed, **Then** it is west-anchored, fully inside the interior, and not a circle.
- **Given** Reality Level increases, **When** the home rebuilds, **Then** claim uses the new rect immediately and still lies inside the interior.
- **Given** growth that would cross a cliff, **When** clip runs, **Then** the overflow is truncated (US-024 T013), not punched through.

## Notes

Do not reimplement interior clip; call the existing helper. Pockets are T004. Do not restyle tiles (US-002).
