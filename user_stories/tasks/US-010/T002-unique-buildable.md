# T002: Unique Office Max buildable with HP

**Story**: US-010  
**Status**: Todo  
**Owner**: Gameplay  
**Depends on**: US-001 T006, US-007  
**Parallel**: with T001

## Goal

Office Max is a **unique** buildable (max **one** enabled per match), placeable under US-001 / US-003 rules, costing **iron** to place (US-007), with **server-side HP** like other buildings (suggested **16**). Destructible, not immortal.

## Files

- `buildings/building_data.gd` — `unique_building`; IRS pattern
- `buildings/building.gd` — `max_hitpoints` / `hitpoints` / `destroyed`
- New `buildings/buildables/office_max.gd` (+ `.tscn` / `.tres`)
- `_globals/building_manager.gd` — placement + uniqueness reject
- Build HUD — wire T001 icons

## Requirements

- FR-001, FR-006, AC6, MR-002, MR-003
- Placement: entire footprint Reality-claimed, outside tiles, not dungeon, clear (US-001). Reject if footprint intersects Fantasy (US-003).
- Placement spends iron per the shared builder / US-007 (separate from restock iron in T003).
- Ghost/preview is **not** an enabled Office Max.
- Second placement while one is enabled: server rejects.
- HP suggested 16 (US-011). Visible health bar may reuse enemy/building bar pattern.

## Acceptance

- **Given** iron and a legal Reality footprint and no Office Max exists, **When** placement is confirmed, **Then** one enabled Office Max is created with HP.
- **Given** an Office Max already exists, **When** another placement is requested, **Then** the server rejects it.
- **Given** Office Max HP, **When** it takes damage to 0, **Then** it can be destroyed (T005); it is not immortal.

## Notes

Restock is T003. Ruin swap is T005. Do not implement US-011 goblin AI here.
