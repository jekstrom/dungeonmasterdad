# T001: Homes never occupy the same cells

**Story**: US-025  
**Status**: Todo  
**Depends on**: US-001 T002, US-003 T002  
**Parallel**: no

## Goal

Reality and Fantasy **home** rectangles never cover the same cells. Adjacent is allowed. Inclusion is **center-point**.

## Files

- `zones/scripts/zone.gd` — `home_rect` rebuild / clip
- `zones/scripts/reality_claim.gd` — Reality home covers
- `zones/scripts/fantasy_claim.gd` — Fantasy home covers
- `scripts/procedural_dungeon/zone_drift_claim.gd` — today allows both homes to cover a cell and then picks a winner; homes themselves must not overlap after this story
- Suggested shared resolve (new or on `zone.gd`): run after either home rebuilds

## Requirements

- FR-001, AC1
- A cell’s center is inside at most one home rect.
- Do not implement pushback math here beyond “if they intersect, they are invalid until T002/T003 resolve.”
- Do not change pocket override (T004).
- Do not restyle tiles here (T005).

## Acceptance

- **Given** resolved homes, **When** every interior cell is queried, **Then** Reality home and Fantasy home are disjoint.
- **Given** two homes that only share an edge, **When** center-point inclusion is used, **Then** no cell is in both.

## Notes

US-001 FR-010 and US-003 FR-010 allowed overlap. This task is the invariant those FRs no longer get. Occupancy on a cell still uses claim (home ∪ pockets), not a circle.
