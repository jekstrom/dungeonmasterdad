# T001: Fantasy claim API

**Story**: US-003  
**Status**: Todo  
**Depends on**: none  
**Parallel**: no

## Goal

One host-authoritative answer to “is this point Fantasy?” Coverage is the **union of the Fantasy home rectangle and all live Fantasy pockets**. Circles MUST NOT be the occupancy source.

## Files

- `zones/scripts/zone.gd` — already has `home_rect`, `_place_fantasy_home`, and `clip_pocket_rect`; still has `CircleShape2D` / `draw_circle` fallback. Stop using the circle as claim.
- Fantasy zone scene / script (`zones/fantasy_zone.tscn`, Reality’s counterpart)
- New small claim helper (suggested: `zones/scripts/fantasy_claim.gd` or methods on the Fantasy zone): `is_claimed_cell(Vector2i)`, `is_claimed_world(Vector2)`, home rect, live pocket list.
- `_globals/signal_bus.gd` — emit when home or pocket set changes.
- Reality claim API from US-001 — needed to evaluate FR-010 overlap (do not reimplement Reality).

## Requirements

- FR-001, Key Entity **Fantasy Claim**
- Default region shape is axis-aligned rectangle, optionally snapped to the 128px tile grid.
- A point is Fantasy-claimed if a live Fantasy pocket covers it (and wins overlap per T004) or else the Fantasy home covers it under FR-010.
- **FR-010 (homes overlap, no pocket):** Paper Pushers blocked (T005), buildings rejected (T007), skeletons banned unless a **Reality pocket** covers the point (T008 / US-001). Document the query here; implement the behaviors in T005–T008.

## Acceptance

- **Given** a home rect and zero pockets, **When** a cell inside the home is queried, **Then** it is Fantasy-claimed; a cell outside is not.
- **Given** a live pocket, **When** a cell inside the pocket and outside the home is queried, **Then** it is Fantasy-claimed.
- **Given** the old circle radius, **When** claim is evaluated, **Then** the circle is ignored.

## Notes

Do not grow the home here (T002). Do not create pockets here (T004). Do not displace Paper Pushers here (T005). Occupancy debug can stay code-drawn.
