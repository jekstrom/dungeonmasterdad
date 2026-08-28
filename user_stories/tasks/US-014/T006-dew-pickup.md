# T006: Green Mt Dew restores mana (DM-only)

**Story**: US-014  
**Status**: Done  
**Depends on**: T001  
**Parallel**: with T002–T005

## Goal

A green Mt Dew world pickup, when the **DM** collects it, adds the configured mana (default +25) up to max. Paper Pushers do not collect it. Overflow is wasted; the can is still consumed. Code Red and Baja Blast stay non-mana.

## Files

- `pickups/mtdew.tres` (new) — `ItemData` next to `pickups/code_red.tres` so `ItemDatabase.load_items_from_folder("res://pickups/")` sees it. `name` green Mt Dew; `auto_use = true`; `pickup_char = "dm_only"`; `texture = pickups/mtdew/mtdew.png` (**32×32**); pickup sound like other Dew/power-ups.
- `pickups/effects/restore_mana.gd` (new) — `class_name ItemEffectRestoreMana extends ItemEffect`; `@export var mana_amount: int = 25`; `use()` calls host `DmManager.add_mana`.
- `pickups/scripts/item_pickup.gd` — already routes DM vs Player via `pickup_char`. Do not grant mana on the Player branch. No change required if `dm_only` is set; verify the DM `auto_use` path calls `item_data.use()` on the server.
- `pickups/mtdew/mtdew.gd` — empty `extends ItemPickup`. Prefer the shared `pickups/pickup.tscn` + `.tres` (Code Red pattern). Do not require a custom pickup scene.
- `test_harness/procedural_dungeon/us014_dew_effect_test.gd` (+ `.tscn`) — dm_only auto_use +25, clamp at max, Paper Pusher skip, Code Red is not mana.

## Requirements

- FR-002, AC4, AC5
- Edge: at max mana, **consume** the can, clamp mana, do not duplicate cans (`auto_use` true).
- Host-authoritative: `handle_pickup` already runs `use()` on the server; `add_mana` must no-op or ignore on clients (T001).
- Do **not** unlock knightling (US-016). Do **not** add restore-mana to `pickups/code_red.tres`.
- Dungeon placement of Dew cans is US-016. This task only makes the item correct when it exists in the world (tests may instance it).

## Acceptance

- **Given** a green Dew `ItemData` with `pickup_char` `dm_only`, **When** a Paper Pusher overlaps the pickup, **Then** they do not gain DM mana and the can is not collected for them.
- **Given** the DM at 0/100 mana, **When** they pick up one green Dew, **Then** mana is 25 (default) and the pickup is consumed.
- **Given** the DM at 90/100, **When** they pick up one green Dew, **Then** mana is 100 and the can is gone (no second can spawned).
- **Given** Code Red pickup, **When** it is used, **Then** mana is unchanged by that item (existing fireball unlock / Fantasy Level effect may still run).

## Notes

`ItemDatabase` does not recurse into `pickups/mtdew/`; the `.tres` must live in `pickups/`. Knightling unlock on first Dew is a **second** effect in US-016, not this resource’s job yet.
