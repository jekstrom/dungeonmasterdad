# T002: Fantasy pocket geometry, overlay key, expire

**Story**: US-031  
**Status**: Todo  
**Depends on**: T001, US-003 T004  
**Parallel**: with T003, T004

## Goal

A successful cast creates one **axis-aligned Fantasy pocket** (default **3×3** cells, **8s**) clipped to the map interior, tagged overlay **`"blizzard"`**. When duration ends the pocket is gone in the same tick as slow/factory restore (those restores are T003/T004).

## Files

- `zones/FantasyZone.gd` — `spawn_pocket(origin, size, duration, overlay)`, `clip_pocket_rect`, expire timer, `fantasy_pocket_expired`. Overlay `"blizzard"` already selects `sprites/blizzard_overlay.png` (T005 asserts art).
- `_globals/dm_manager.gd` — `_blizzard_rect_from_spell`, `BLIZZARD_DURATION`, `BLIZZARD_POCKET_CELLS`, `_on_fantasy_pocket_expired` → `drop_blizzard_for_pocket`.
- `test_harness/procedural_dungeon/us017_blizzard_cast_test.tscn` — already asserts pocket rect / duration. Keep green. Optional `us031_pocket_test.gd` if you add clip-to-interior or overlay-key asserts not already covered.

## Requirements

- FR-003, FR-004, FR-007, FR-008, AC3, AC4, AC7, AC10
- Shape is a **rect**, not a circle. Targeting uses cell origin minus half size so the confirm point is the center.
- Clip: `FantasyZone.clip_pocket_rect` / interior (US-024). Empty clip is T001 reject.
- Occupancy: do **not** reimplement T011. PP walk; no wall. Buildings reject via existing US-003 T007 (`is_area_clear` / Fantasy claim).
- Skeletons allowed unless Reality-claimed (US-001). Do not ban goblins (US-011).
- Newer Reality pocket wins **claim**; blizzard **slow rect** stays the cast rect for the duration (US-031 edge).
- Expire: `SignalBus.fantasy_pocket_expired` must drop `_blizzard_effects` for that `pocket_id` so T003/T004 see no slow.

## Acceptance

- **Given** a successful cast, **When** Fantasy pockets are read, **Then** there is one rect of size 3×3 (or the clipped subset) with overlay `"blizzard"` and duration ~8s.
- **Given** a building footprint intersecting that pocket, **When** placement is requested, **Then** it is rejected and no building is created.
- **Given** an existing factory in the pocket, **When** the pocket is live, **Then** the factory is not destroyed by occupancy.
- **Given** ~8s elapsed, **When** expire runs, **Then** `get_pocket` is empty and `live_blizzard_count() == 0`.

## Notes

Ice draw is T005. Do not grow Fantasy **home** from this cast (dice / FL is US-016).
