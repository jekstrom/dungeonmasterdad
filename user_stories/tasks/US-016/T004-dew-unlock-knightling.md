# T004: First green Dew unlocks knightling

**Story**: US-016  
**Status**: Done  
**Depends on**: T003  
**Parallel**: after T003; before T005 if sharing `dm_hud.gd`

## Goal

Picking up **green Mt Dew** still restores mana (US-014). The **first** Dew of the match also unlocks knightling on the server. Later Dews grant mana only; the unlock stays true. The unlock itself does not spend Fantasy Level or mana.

## Files

- `pickups/effects/unlock_knightling.gd` (new) **or** a small generic `ItemEffectUnlock` with `@export var unlock_id: String` — prefer a dedicated class next to `ItemEffectUnlockFireball` if you need a second effect on the same `.tres` without sharing fireball's Fantasy Level grant. `use()` calls `DmManager.unlock("knightling")` (server no-op already inside `DmManager.unlock`).
- `pickups/mtdew.tres` — keep `ItemEffectRestoreMana` (`mana_amount = 25`). **Append** the knightling unlock effect to `effects`. Do not remove mana. Do not add Fantasy Level.
- `pickups/effects/unlock_fireball.gd` / `pickups/code_red.tres` — do not grant knightling.
- `test_harness/procedural_dungeon/us016_dew_unlock_test.gd` (+ `.tscn`) — first Dew unlocks + mana; second Dew mana only; Code Red does not unlock knightling; Paper Pusher skip; no FL tax.

## Requirements

- FR-002, FR-006, AC2, AC3, AC7
- Order in `effects`: restore mana then unlock is fine; both must run on one `ItemData.use()`.
- First Dew of the match: `DmUnlocks.dm_unlocks["knightling"]` becomes true **and** mana increases (from 0 → 25 by default).
- Already unlocked: Dew still consumed, mana granted (clamp per US-014), flag remains true.
- Host-authoritative: only the server `use()` path; clients must not locally flip the flag in a way that sticks (T007 replicates).
- Do not reintroduce a Fantasy Level tax on summon or on this unlock.
- Dew stays `dm_only` + `auto_use`.

## Acceptance

- **Given** knightling locked and mana 0, **When** the DM uses / picks up one green Dew, **Then** mana is 25 and `knightling` is unlocked.
- **Given** knightling already unlocked, **When** another green Dew is used, **Then** mana increases (or clamps) and the unlock stays true.
- **Given** Code Red, **When** it is used, **Then** knightling remains locked (fireball unlock may still run).
- **Given** a Paper Pusher overlapping Dew, **When** pickup is evaluated, **Then** they do not unlock knightling and the can remains.
- **Given** the unlock, **When** Fantasy Level is read, **Then** Dew did not change it.

## Notes

HUD visibility is T005. `us014_dew_effect_test.gd` still checks mana only; it may start seeing knightling unlock as a side effect of `dew.use()` — that is OK as long as mana assertions stay. If that test resets `DmUnlocks.dm_unlocks["fireball"]`, also reset `knightling` so leftover autoload state does not leak into later scenes in the same process (Godot `--quit-after` is per scene, but be explicit in US-016 tests).
