# T003: Paper Pusher slow inside the rect

**Story**: US-031  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T002, T004

## Goal

While a blizzard is live, a Paper Pusher **inside the world rect** moves at **50%** of `BASE_MOVE_SPEED`. Outside, baseline. Leave the rect → baseline immediately. Do **not** slow the DM or monsters.

## Files

- `_globals/dm_manager.gd` — `blizzard_slow_factor_at(world)`, `BLIZZARD_SLOW_FACTOR` 0.5, `_blizzard_world_rect`.
- `player/player.gd` — `blizzard_slow_factor()` / `get_move_speed()`. Walk/slick already use `get_move_speed()`. Confirm idle→walk and dew-slick desired speed both go through that helper.
- `player/scripts/player_walk_state.gd` — uses `player.blizzard_slow_factor()` on desired velocity. Keep it consistent with `get_move_speed()`.
- `dm/dm.gd` / `monsters/enemy.gd` — must **not** multiply blizzard factor.
- `test_harness/procedural_dungeon/us017_blizzard_cast_test.tscn` — PP inside ~150 if baseline 300. Keep green. Add `us031_pp_slow_test.gd` (+ `.tscn`) if you need: PP outside unchanged; leave-rect restores; DM `get_move_speed` if any is unscaled; goblin `run_speed` unchanged.

## Requirements

- FR-005, FR-008, AC5, AC9, MR-002
- Factor applies only while `has_point` on the **spell world rect** (cell rect × 128), not “anywhere Fantasy home.”
- Respawn into the pocket: slowed, not shoved (US-003 T011 / US-001 spawn).
- Dew slick + blizzard: both may apply; do not drop slick. Slow still comes from `get_move_speed()` / walk state’s desired.
- Expire: next move tick is baseline (same tick as pocket removal).

## Acceptance

- **Given** a PP inside the live rect, **When** `get_move_speed()` is read, **Then** it is `BASE_MOVE_SPEED * 0.5` (300 → 150).
- **Given** a PP outside, **When** blizzard is live, **Then** speed is baseline.
- **Given** a PP who walks out of the rect, **When** still during duration, **Then** speed is baseline.
- **Given** a goblin or DM in the rect, **When** they move, **Then** they are not blizzard-slowed.

## Notes

Factory interval is T004. Do not change occupancy.
