# T002: Ability mana cost and unlock catalog

**Story**: US-014  
**Status**: Done  
**Depends on**: none  
**Parallel**: with T001

## Goal

Every spell and summon **declares** an integer mana cost (and optional unlock id) in one place. HUD buttons and `try_cast` read this table instead of hard-coding 150 Fantasy Level.

## Files

- `dm/dm_ability_catalog.gd` (new) — `class_name` or a RefCounted/static helper: `cost(ability_id) -> int`, `unlock_id(ability_id) -> String` (empty = no unlock gate).
- Callers in later tasks: `_globals/dm_manager.gd`, `gui/dm/dm_hud.gd`.
- `test_harness/procedural_dungeon/us014_ability_catalog_test.gd` (+ `.tscn`) — defaults, empty knightling unlock, unknown id reject.

## Ability ids and defaults

| `ability_id` | Mana cost | Unlock id | This story |
|---|---|---|---|
| `gremlin` | 20 | _(none)_ | Summon exists |
| `knightling` | 40 | _(none here)_ | Summon exists; US-016 owns unlock |
| `fireball` | 15 | `fireball` | Spell exists; `DmUnlocks` already has the key |
| `bemidji_blizzard` | 30 | `bemidji_blizzard` | No spell body (US-017). Catalog + reject only |
| `dad_all_powerful` | 0 | `dad_all_powerful` | No form (US-021). Catalog only |

Unknown `ability_id`: treat as uncastable (no deduct, no effect). Do not invent a 0-cost default for typos.

## Requirements

- FR-003, FR-008
- Costs are integers. Tunable constants, not scattered magic numbers in the HUD.
- Knightling must **not** gain a new unlock gate in this story (independent test expects knight to be a mana-gated action, not a locked one).
- Baja Blast / Code Red are not catalog abilities and not mana cans.

## Acceptance

- **Given** the catalog, **When** `cost("gremlin")` is read, **Then** it is 20 (or the configured default).
- **Given** `fireball`, **When** unlock is read, **Then** it is `fireball`.
- **Given** `knightling`, **When** unlock is read, **Then** it is empty so current knight spawn still works after T004 pays mana.
- **Given** an unknown id, **When** cost/unlock is queried, **Then** callers can reject without throwing.

## Notes

Do not implement blizzard or Dad All Powerful effects. Do not put costs on `ItemData`. Fireball’s existing HUD `update_fantasy_level(15)` grant is **not** a cost; T005 must not treat it as payment.
