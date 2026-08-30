# T001: ItemData row flag (active vs static)

**Story**: US-030  
**Status**: Todo  
**Depends on**: none  
**Parallel**: with T004

## Goal

Every `ItemData` declares **active** (usable in the top row) or **static** (ingredient in the bottom row). Existing `.tres` files are flagged. Pickup and `auto_use` are unchanged. No slotted bag yet.

## Files

- `pickups/scripts/item_data.gd` — add `@export_enum("active", "static") var inventory_row: String = "static"` (or an equivalent enum). Optional `@export var channel_use: bool = false` here so T006 does not invent a second flag later; default false. Blank form: `channel_use = true`.
- All `res://pickups/*.tres` (and `pickups/bajablast/bajablast.tres`) — set `inventory_row`. Suggested defaults from the story:

| Row | Paths |
|---|---|
| Active | `blank_form.tres`, `filled_form.tres`, `tax_form.tres`, `mtdew.tres`, `d6.tres`, `d20.tres`, `cloak.tres`, `code_red.tres`, `bajablast/bajablast.tres` |
| Static | `wood.tres`, `paper.tres`, `metal.tres`, `coal.tres`, `stone.tres` |

- `test_harness/procedural_dungeon/us030_item_row_flags_test.gd` (+ `.tscn`) — load each path; assert row; blank form `channel_use`; wood/paper/metal static.

## Requirements

- FR-002
- `pickup_char` stays `player_only` / `dm_only`. Do not infer row from it (stone is `dm_only` and **static**).
- `auto_use` items still skip the bag in `ItemPickup.handle_pickup`. Flag them anyway so a later disable of `auto_use` has a row.
- Do not change textures, names, or costs.

## Acceptance

- **Given** `ItemData`, **When** a `.tres` is loaded, **Then** `inventory_row` is `"active"` or `"static"`.
- **Given** wood, paper, and metal, **When** read, **Then** they are **static**.
- **Given** blank form, **When** read, **Then** it is **active** and `channel_use` is true.

## Notes

Host placement is T002. Dew may still `auto_use` into mana (US-014) and never sit in a cell — that is existing pickup behavior, not a T001 fail.
