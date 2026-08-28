# T007: DM HUD current and max mana

**Story**: US-014  
**Status**: Done  
**Depends on**: T001, T004  
**Parallel**: no (same `dm_hud` files as T004)

## Goal

While the DM HUD is shown, the DM sees **current and max mana**. A ColorRect/bar is enough. Reuse `pickups/mtdew/mtdew.png` (**32×32**) as a pip. Do not invent a second can silhouette.

## Files

- `gui/dm/dm_hud.tscn` — meter (ColorRect fill or equivalent) + label `current/max` + TextureRect pip using `mtdew.png`. Keep it on the DM HUD, not the Fantasy Level bar in `gui/hud.tscn` (that bar is zone progression).
- `gui/dm/dm_hud.gd` — connect `DmManager.mana_changed` (and read initial values in `turn_on`). Update fill width/ratio from `current / max` (avoid div by zero).
- `test_harness/procedural_dungeon/us014_mana_hud_test.gd` (+ `.tscn`) — 0/100 text and empty bar, live update on spend, dew pip, no Paper Pusher mana control.

## Requirements

- FR-007, AC6
- Story art: no new assets. Pip is the existing Dew sprite; meter is a ColorRect/bar.
- Other clients **may** see a simple indicator; not required. They must not author mana. Do not put writable cheats on the Paper Pusher HUD.
- Optional: grey summon/fireball buttons when `current < cost` — convenience only; T003/T004 still refuse if pressed.

## Acceptance

- **Given** mana 0/100, **When** the DM HUD is visible, **Then** it shows 0 and 100 (text and empty/near-empty bar).
- **Given** a Dew pickup or a successful cast, **When** mana replicates, **Then** the meter matches the new current without a restart.
- **Given** a Paper Pusher client, **When** they look at their HUD, **Then** they do not get a control that sets DM mana.

## Notes

`gui/hud.gd` Fantasy / Reality bars stay. Do not replace Fantasy Level display with mana. Unlock visibility for fireball (`Fireball` ColorRect `visible`) stays T005/`on_dm_unlock`.
