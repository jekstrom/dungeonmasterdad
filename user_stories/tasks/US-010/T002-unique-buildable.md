# T002: Unique Office Max buildable

**Story**: US-010  
**Status**: Todo  
**Owner**: Gameplay  
**Depends on**: US-001 T006, US-007  
**Parallel**: with T001

## Goal

Office Max is a **unique** buildable (max **one** enabled per match), placeable under US-001 / US-003 rules, costing **iron** (US-007).

## Files

- `buildings/building_data.gd` — `unique_building` already exists; IRS is the pattern (`buildings/buildables/irs.*`)
- New `buildings/buildables/office_max.gd` (+ `.tscn` / `.tres`)
- `_globals/building_manager.gd` — placement + uniqueness reject
- Build HUD — wire T001 icons

## Requirements

- FR-001, AC5, MR-002
- Placement: entire footprint Reality-claimed, outside tiles, not dungeon, clear (US-001). Reject if footprint intersects Fantasy (US-003).
- Iron cost only for this story (no paper/wood/smoke spend on place beyond whatever the shared builder already charges for iron buildings).
- Ghost/preview is **not** an enabled Office Max (edge).
- Second placement while one is enabled: server rejects; no second instance.

## Acceptance

- **Given** iron and a legal Reality footprint and no Office Max exists, **When** placement is confirmed, **Then** one enabled Office Max is created.
- **Given** an Office Max already exists, **When** another placement is requested, **Then** the server rejects it.
- **Given** a Fantasy-intersecting or dungeon footprint, **When** placement is requested, **Then** it is rejected.

## Notes

Restock is T003. Destroy / rebuild is T005. Do not implement US-011 goblin raids here.
