# T006: Dice Fantasy Level grows the Fantasy home rectangle

**Story**: US-016  
**Status**: Done  
**Depends on**: T002  
**Parallel**: with T004, T005

## Goal

When dice raise Fantasy Level, the Fantasy **home region** grows as an **axis-aligned rectangle**, not a circle. Occupancy (Paper Pusher block, pockets) stays US-003. This task only makes the live `home_rect` follow Fantasy Level after a die grant.

## Files

- `zones/scripts/zone.gd` — already: `DmManager.fantasy_level_changed` → `clip_home_to_interior()`; `_place_fantasy_home` expands a seed rect by `growth = fantasy_level` on each edge and clips to map interior. Confirm that path runs for the **non-reality** zone when dice call `update_fantasy_level`. If `home_rect` is empty because map bounds are not committed, do not invent a second growth system; tests should commit interior (US-024 `MapBounds`) or call `clip_home_to_interior` after setting bounds.
- `zones/fantasy_zone.tscn` — no new scene. Keep using the existing Fantasy zone node in playground.
- `_globals/dm_manager.gd` — `update_fantasy_level` already RPCs `request_fantasy_level_incrase` and emits `fantasy_level_changed`. Dice (T002) must use that; do not set `fantasy_level` on the client only.
- `test_harness/procedural_dungeon/us016_fantasy_home_growth_test.gd` (+ `.tscn`) — with committed interior, record `home_rect`, use d6/d20 (or `update_fantasy_level` + the same `on_level_changed` path), assert `home_rect` is a `Rect2i` whose size grew (or expanded toward the west while still inside interior), not a circle-only presentation when interior exists.

## Requirements

- FR-004, Independent Test ("Fantasy home rectangle grows")
- Growth MUST use `Zone.home_rect` (`Rect2i`). Circles MUST NOT be the default once interior is committed (`_draw` already prefers `home_rect` when size > 0).
- Clip to map interior (already `bounds.intersect_interior`). Do not grow past cliffs (US-024).
- Seed remains the dungeon AABB / east strip (`_fantasy_seed_rect`); do not relocate the home to the Paper Pusher west edge.
- Do **not** implement Paper Pusher push-out, building reject, or pockets (US-003 / US-017).
- Reality home must not grow because a die was picked up.

## Acceptance

- **Given** committed map interior and a Fantasy zone with a non-empty `home_rect`, **When** Fantasy Level increases by a d6-scale amount, **Then** `home_rect.size` is larger on at least one axis (or the rect expanded) and still lies inside the interior.
- **Given** the same increase, **When** presentation is inspected, **Then** the zone uses the rectangle path (`home_rect` size > 0), not falling back to circle-only because bounds were cleared.
- **Given** a Reality zone, **When** only Fantasy Level changes, **Then** Reality `home_rect` is unchanged.

## Notes

`on_level_changed` still updates `radius` when `home_rect` is empty — that is the no-bounds fallback, not the story default. Headless tests should attach or stub a `level_manager` in group `level_manager` with `get_map_bounds()` / `dungeon_cell_bounds()` like US-024 zone clip tests (`us024_zone_clip_test.gd`).
