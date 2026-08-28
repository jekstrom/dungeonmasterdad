# T002: Dice raise Fantasy Level on pickup

**Story**: US-016  
**Status**: Done  
**Depends on**: none  
**Parallel**: with T001, T003

## Goal

A **d6** and a **d20** world pickup, when the **DM** collects them, increase Fantasy Level by a die-scale amount (defaults **+6** and **+20**). They do not restore mana. Paper Pushers do not collect them. At whatever Fantasy cap exists later, still consume the die and clamp; there is no cap today.

## Files

- `pickups/effects/increase_fantasy_level.gd` (new) — `class_name ItemEffectIncreaseFantasyLevel extends ItemEffect`; `@export var fantasy_amount: int = 6`; `use()` calls host `DmManager.update_fantasy_level`. Do **not** reuse `pickups/effects/heal_effect.gd` (that script is misnamed and hard-codes +50).
- `pickups/d6.tres` — already `name` D6, `pickup_char = "dm_only"`, texture `pickups/d6/d6.png` (**32×32**). Set `auto_use = true` and attach the effect with `fantasy_amount = 6`. Add a short description.
- `pickups/d20.tres` — same, `fantasy_amount = 20`, texture `pickups/d20/d20.png` (**32×32**).
- `pickups/scripts/item_pickup.gd` — already routes DM vs Player via `pickup_char`. No change if `dm_only` + `auto_use` are set; verify the DM path calls `item_data.use()` on the server (same as Dew).
- `test_harness/procedural_dungeon/us016_dice_effect_test.gd` (+ `.tscn`) — resource checks, +6 / +20, no mana change, Paper Pusher skip, consume, two sequential pickups.

`ItemDatabase.load_items_from_folder("res://pickups/")` already sees `d6.tres` / `d20.tres` at that folder root.

## Requirements

- FR-003, FR-005, AC5, AC6, AC7
- Suggested defaults: d6 **+6**, d20 **+20** (fixed, testable). A roll of 1–N is allowed later; do not make RNG the default in this task.
- Dice MUST NOT call `DmManager.add_mana` or attach `ItemEffectRestoreMana`.
- `auto_use = true` so they do not go into Paper Pusher inventory (`PlayerManager.add_item_to_inventory`).
- Host-authoritative: `handle_pickup` already runs `use()` on the server; `update_fantasy_level` already no-ops unless `multiplayer.is_server()`.
- Consume the die even if Fantasy Level would not change (no cap today; if a cap is added later, clamp, still consume).
- Two dice in one cell: both collectable sequentially (two `ItemPickup` nodes, two `body_entered`). Do not merge stacks in this task.
- Green Dew mana grant stays US-014; do not add Fantasy Level to Dew here (Code Red already grants FL + fireball).

## Acceptance

- **Given** `pickups/d6.tres`, **When** the DM uses it from Fantasy Level 0, **Then** Fantasy Level is 6 and mana is unchanged.
- **Given** `pickups/d20.tres`, **When** the DM uses it, **Then** Fantasy Level increases by 20 and mana is unchanged.
- **Given** `pickup_char` `dm_only`, **When** a Paper Pusher overlaps a die pickup, **Then** they do not gain Fantasy Level and the die is not consumed.
- **Given** the DM overlaps a die, **When** pickup resolves, **Then** the pickup is consumed (hidden / pooled) and `fantasy_level_changed` fired on the host path.
- **Given** two die `ItemPickup`s, **When** the DM collects them one after another, **Then** both grants apply (6 then 20 → +26).

## Notes

Do not grow the Fantasy home rectangle in this task (T006). Do not place dice in the generator (T001). Do not unlock knightling. `Lobby.is_network_server()` vs `multiplayer.is_server()`: `update_fantasy_level` already uses `multiplayer.is_server()`, which is true for `OfflineMultiplayerPeer` — that is what headless tests need.
