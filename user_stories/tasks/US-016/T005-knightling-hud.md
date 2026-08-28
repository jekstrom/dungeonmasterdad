# T005: Knightling HUD until unlock, then usable with mana

**Story**: US-016  
**Status**: Done  
**Depends on**: T003  
**Parallel**: after T004 if sharing `gui/dm/dm_hud.gd` / `.tscn`

## Goal

The spawn-knightling control is **not usable** until knightling is unlocked. After unlock, with enough mana (US-014, cost 40), the existing HUD action summons. Match fireball: the `SpawnKnight` ColorRect starts hidden and appears on `SignalBus.on_dm_unlock`.

## Files

- `gui/dm/dm_hud.tscn` — `SpawnKnight` `visible = false` by default (same as `Fireball`). Keep `monsters/knight/knight.png` (**32×32** / HUD button). Fix the knight button tooltip (`Summon Gremlin` is wrong).
- `gui/dm/dm_hud.gd` — `on_dm_unlock`: if `unlock_name == AbilityCatalog.KNIGHTLING` (or `"knightling"`), show `SpawnKnight`. In `turn_on` / `_ready` after HUD exists, apply **current** unlock flags so a HUD that turns on after the pickup still shows the button (fireball today only listens when `turn_on` connects — copy that, and also read `DmUnlocks.dm_unlocks` so a late `turn_on` is not blank).
- `_on_knight_button_pressed` already calls `DmManager.request_cast(KNIGHTLING)`. Keep it. Do not subtract Fantasy Level. Optional: ignore presses while the parent ColorRect is hidden.
- `test_harness/procedural_dungeon/us016_knightling_hud_test.gd` (+ `.tscn`) — hidden while locked; visible after unlock signal; press with mana 40 + unlock spawns once; press while locked does not spawn even with mana.

## Requirements

- AC4, FR-006
- Locked: knight control not shown (or not usable). Prefer hidden like fireball, not a grey button that still RPCs.
- Unlocked + mana ≥ 40: one `spawn_knight_cast` / existing knight scene spawn path (US-012 combat unchanged).
- Unlocked + mana 0: no spawn (US-014 `try_cast`). Button may stay visible.
- Gremlin stays visible and ungated.
- No new art. Do not add a blizzard button (US-017).
- `root.gd` still turns `DmHud` on for the host DM. Paper Pusher HUD must not gain a knight spawn control.

## Acceptance

- **Given** a fresh match (knightling locked), **When** the DM HUD is shown, **Then** the knight spawn control is not visible.
- **Given** `on_dm_unlock` with `knightling`, **When** the HUD handles it, **Then** the knight control is visible.
- **Given** unlock + mana 40, **When** the knight button is pressed on the host, **Then** mana becomes 0 and exactly one knight spawn path runs.
- **Given** locked + mana 40, **When** `request_cast("knightling")` or a hidden-button press is attempted, **Then** no knight spawns and mana is unchanged.
- **Given** a successful summon, **When** Fantasy Level is read, **Then** it was not reduced.

## Notes

Do not implement lethal knightling hits (US-012). Late-join flag sync is T007; this task only reacts to the signal / current dict. T004 and T005 both may edit `dm_hud.gd` if T004 tries to show the button — leave visibility here.
