# T001: Reality claim API

**Story**: US-001  
**Status**: Todo  
**Depends on**: none  
**Parallel**: no

## Goal

One host-authoritative answer to “is this point Reality?” Coverage is the **union of the Reality home rectangle and all live Reality pockets**. Circles MUST NOT be the occupancy source.

## Files

- `zones/scripts/zone.gd` — already has `home_rect` and `clip_pocket_rect`; still drives `CircleShape2D` / `draw_circle` when the rect is empty. Stop using the circle as claim.
- `zones/RealityZone.gd` — Reality-specific claim owner.
- New small claim helper (suggested: `zones/scripts/reality_claim.gd` or methods on the Reality zone): `is_claimed_cell(Vector2i)`, `is_claimed_world(Vector2)`, home rect, live pocket list.
- `_globals/signal_bus.gd` — emit when home or pocket set changes.

## Requirements

- FR-001, Key Entity **Reality Claim**
- Default region shape is axis-aligned rectangle, optionally snapped to the 128px tile grid.
- A point is Reality-claimed if a live pocket covers it (and wins overlap per T004) or else the home covers it. FR-010 overlap with Fantasy homes is noted here but **not implemented** (US-003).

## Acceptance

- **Given** a home rect and zero pockets, **When** a cell inside the home is queried, **Then** it is claimed; a cell outside is not.
- **Given** a live pocket, **When** a cell inside the pocket and outside the home is queried, **Then** it is claimed.
- **Given** the old circle radius, **When** claim is evaluated, **Then** the circle is ignored.

## Notes

Do not grow the home here (T002). Do not create pockets here (T004). Do not draw player-facing overlays here (T003). Occupancy debug can stay code-drawn.
