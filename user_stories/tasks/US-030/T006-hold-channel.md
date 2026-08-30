# T006: Hold hotkey to finish a channel

**Story**: US-030  
**Status**: Todo  
**Depends on**: T005  
**Parallel**: with T007

## Goal

If the item in the active cell has `channel_use` (blank form), the owner must **hold** that cell’s hotkey for the full channel. **Release** cancels with no complete (blank remains). Move, damage, and death still cancel (US-009). Instant items stay tap-to-use (T005).

## Files

- `pickups/scripts/item_data.gd` — `channel_use` (if not added in T001).
- `player/player.gd` — fill already has `begin_fill` / `tick_fill` / `cancel_fill`. Change **start** to slot-hotkey **pressed**, **complete** only while that action stays down; **released** → `cancel_fill`. Do not complete on press. Duration knobs stay US-009 (3s / 6s). Type chosen at start: keep existing `standard`/`tax` argument (e.g. hold Q + a modifier, or a default type, or a one-shot prompt). Do **not** bring back global R/T.
- Input: `is_action_pressed("inv_slot_n")` each tick while filling that index; if false, cancel.
- DM: if no DM item is `channel_use`, the same hold/release path still exists and no-ops on instant items.
- Local channel bar already on PP (`_update_fill_bar`); show it while holding.
- `test_harness/procedural_dungeon/us030_hold_channel_test.gd` (+ `.tscn`) — begin channel on slot 0; tick without “held” → cancel, blank kept; held for duration → complete. Double complete still one item (US-009 T003).

## Requirements

- FR-005, AC4
- Release == cancel. Do not consume the blank on cancel.
- Channel length and fill outcomes stay US-009 (`standard_form_rl`, tax no RL until IRS).
- If the player swaps the filling cell away mid-channel (T007), cancel.

## Acceptance

- **Given** a blank form in active 0 and a hold for the full standard duration, **When** the host ticks, **Then** the blank becomes a filled form (or tax if that type was chosen).
- **Given** a channel in progress, **When** the hotkey is released, **Then** the blank remains and no filled/tax is granted.
- **Given** an instant active item, **When** the key is tapped, **Then** it does not require a hold (T005).

## Notes

Do not retune Reality amounts. Fill type UX can be a small default (standard) plus a documented modifier for tax if a two-option prompt is too heavy — state the choice in the task implementation, but the hold rule is the requirement.
