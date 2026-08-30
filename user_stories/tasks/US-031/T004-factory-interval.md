# T004: Factory interval 2× in the pocket

**Story**: US-031  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T002, T003

## Goal

If a smoke or paper factory **origin** is inside a live blizzard slow rect, its production **interval is 2×**. Remaining time **scales**; do not reset progress to 0. Outside factories unchanged. Ghost and **destroyed** factories do not tick (US-011).

## Files

- `buildings/building.gd` — `sync_blizzard_interval()`, `BLIZZARD_FACTORY_INTERVAL_FACTOR`, `_apply_blizzard_interval_factor` (remaining *= new/old). Hooks: `spell_cast`, `fantasy_pocket_expired`, `map_bounds_cleared`.
- `buildings/buildables/smoke_factory.gd` / `paper_factory.gd` — already call `sync_blizzard_interval()` at the top of `_process`. Keep that. Do not retune `wood_consume_amt` / smoke grants.
- `_globals/dm_manager.gd` — `is_in_blizzard_slow_rect`, `blizzard_factory_interval_factor_at`.
- `test_harness/procedural_dungeon/us017_blizzard_factory_test.tscn` — keep green (2×, 90% remaining, outside unchanged).

## Requirements

- FR-006, FR-008, AC6, AC7, edge: 90% complete
- Origin = `factory_origin()` (`global_position`), not the sprite AABB.
- Multiple live blizzards: if origin is in **any** live rect, factor 2.0 (not stacked 4× unless you document it; **do not stack**).
- Occupancy does not destroy the factory. US-011 raids still can.
- Expire / leave-rect: `_applied_blizzard_factor` back to 1.0 in the same tick as pocket removal; remaining scales down.

## Acceptance

- **Given** a factory origin in the pocket, **When** an interval runs, **Then** `interval` is `_baseline_interval * 2`.
- **Given** 90% complete (10% remaining) when blizzard starts, **When** factor becomes 2, **Then** remaining time doubles; `timer` is not 0.
- **Given** a factory origin outside, **When** blizzard is live, **Then** interval is baseline.
- **Given** expire, **When** `_process` runs, **Then** interval is baseline and production continues from scaled remaining.

## Notes

Do not slow mines or tree harvest. Overlay is T005.
