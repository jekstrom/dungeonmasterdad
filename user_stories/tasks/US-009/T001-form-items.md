# T001: Form items (blank, filled, tax)

**Story**: US-009  
**Status**: Todo  
**Depends on**: none  
**Parallel**: with T005

## Goal

Three inventory items exist and load like paper/wood/metal: **blank form**, **filled standard form**, **tax form**. Pickup art already exists. Do not add a second set of PNGs. Do not convert paper or grant Reality yet.

## Files

- `pickups/forms/blank_form.png`, `filled_form.png`, `tax_form.png` — already 32×32. Wire these as `ItemData.texture`.
- `pickups/blank_form.tres`, `pickups/filled_form.tres`, `pickups/tax_form.tres` — **new**. Put the `.tres` in `res://pickups/` (not only under `forms/`) because `ItemDatabase.load_items_from_folder("res://pickups/")` does **not** recurse. `get_item` can still load by full path as a fallback; the folder scan should still see the `.tres`.
- `pickups/scripts/item_data.gd` — no new fields required. `pickup_char = "player_only"`, `auto_use = false` (paper/metal pattern). Distinct `name` / `description` so HUD stacks do not collide.
- `_globals/item_database.gd` — confirm `get_item("res://pickups/blank_form.tres")` (and filled/tax) resolves. Do not invent a global form meter.
- `test_harness/procedural_dungeon/us009_form_items_test.gd` (+ `.tscn`)

Suggested names: Blank Form, Form (or Filled Form), Tax Form. Paths are the identity for `has_resources` / `consume_resources`.

## Requirements

- FR-008, AC1/AC2 (item identity only)
- Paper Pushers pick them up via existing `ItemPickup`.
- The DM MUST NOT collect them (`player_only`).
- They occupy inventory slots and can drop through `grant_item_or_drop` / `on_item_drop` (same as wood).
- Do not `auto_use` paper or forms. Convert/fill is T002/T003.
- Do not change `pickups/paper.tres`.

## Acceptance

- **Given** the three `.tres` files, **When** `ItemDatabase.get_item` is called with each path, **Then** each loads as `ItemData`, is `player_only`, and is not `auto_use`.
- **Given** a Paper Pusher, **When** `add_item_to_inventory` grants a blank form, **Then** `get_item_count` for that path is 1.
- **Given** a DM overlapping a blank-form `ItemPickup`, **When** pickup resolves, **Then** the pickup stays.

## Notes

Create-form is T002. Art is already imported; do not run Imagine unless a PNG is missing. Keep stacks separate: filled standard and tax must **not** share one `resource_path`.
