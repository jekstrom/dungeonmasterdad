# T004: Fill outcomes — standard Reality vs held tax form

**Story**: US-009  
**Status**: Todo  
**Depends on**: T003  
**Parallel**: no (same complete path as T003)

## Goal

When a **standard** fill completes, Reality Level increases immediately by the standard amount (suggested **+15**). When a **tax** fill completes, Reality Level **does not** change; the tax form stays in inventory until T006. Completing a tax form away from the IRS must not file it.

## Files

- `player/player.gd` (or `form_fill.gd`) — in the **single** host `_complete_fill`: after the item swap, if type is standard, `PlayerManager.update_reality_level(standard_amount)`; if tax, do not call it.
- `_globals/player_manager.gd` — existing `update_reality_level` already RPCs `request_reality_level_increase` and grows the Reality home (US-001). Do not add a second Reality pool.
- `buildings/buildables/paper_factory.gd` — **do not edit** the `update_reality_level(10)` paper cycle. T004 only asserts tax file (T006) and this standard grant relative to that 10: standard +15 is larger than 10; the story **requires** tax-file > paper cycle, not standard vs paper. Keep paper at 10.
- `gui/hud.gd` — already listens to `reality_level_changed`. No new HUD required beyond the existing Reality label.
- `test_harness/procedural_dungeon/us009_fill_outcomes_test.gd` (+ `.tscn`)

## Requirements

- FR-004, FR-005, AC3, AC4
- Host-authoritative RL. Clients must not add Reality locally.
- Standard grant happens **once** per successful standard fill, on the same token as T003 (no double RL).
- Tax complete: inventory has the tax form; `PlayerManager.reality_level` unchanged.
- No IRS needed for standard. No IRS used for tax complete.
- Do not consume the filled standard after granting RL (story keeps it as an item). If inventory is full, `grant_item_or_drop` the filled item; RL still applies for standard.

## Acceptance

- **Given** Reality 0 and a successful standard fill, **When** complete runs, **Then** Reality is 15 (or the configured standard amount) and the player has a filled standard form.
- **Given** Reality 0 and a successful tax fill, **When** complete runs, **Then** Reality is still 0 and the player has a tax form.
- **Given** a tax form in inventory and no IRS, **When** time passes, **Then** Reality does not increase from that form.

## Notes

Filing is T006. Suggested standard +15, tax file +50. Export both on the fill/file code so T006 can read the tax amount from one constant if you colocate knobs.
