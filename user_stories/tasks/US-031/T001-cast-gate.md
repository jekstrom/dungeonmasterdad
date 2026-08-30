# T001: Targeting, unlock/mana gate, atomic spend

**Story**: US-031  
**Status**: Todo  
**Depends on**: US-014, US-017 unlock bit  
**Parallel**: no (owns `launch_blizzard`)

## Goal

Bemidji Blizzard uses the **fireball targeting confirm**, costs **30** mana, and requires unlock. Locked, short mana, or an empty clipped rect: **no pocket, no spend**. A successful cast spends only when a Fantasy pocket id exists.

## Files

- `_globals/dm_manager.gd` — `launch_blizzard` / `request_launch_blizzard` / `_can_try_cast`. Today: clip rect, `try_cast`, **then** `spawn_pocket`. If `spawn_pocket` returns −1, mana is already gone (**FR-002**). Reorder: clip → if empty return false → `spawn_pocket` **or** create pocket then `try_cast` with refund; preferred: **check** `_can_try_cast`, spawn pocket, **then** `try_cast`, and if `try_cast` fails expire the pocket immediately (or reserve mana then spawn). Simplest correct: clip empty → return; `_can_try_cast` false → return; `spawn_pocket`; if id < 0 return **without** `try_cast`; then `try_cast` and if that fails `expire_pocket(id)`.
- `dm/dm.gd` — targeting for `BEMIDJI_BLIZZARD`: `_size_blizzard_reticle`, spell_data `origin` / `size` / `duration` / `slow_factor` / `target`. Keep axis-aligned 3×3 (`BLIZZARD_POCKET_CELLS`).
- `gui/dm/dm_hud.gd` — `_on_blizzard_button_pressed` still `start_spell_cast` only if unlocked (already).
- `dm/dm_ability_catalog.gd` — cost 30; do not retune.
- `test_harness/procedural_dungeon/us017_blizzard_cast_test.tscn` must stay green. Add `us031_cast_gate_test.gd` (+ `.tscn`) for the spend-after-fail case: force `clip_pocket_rect` / off-map target → mana unchanged.

## Requirements

- FR-001, FR-002, FR-003, FR-010, FR-011, AC1, AC2, AC3
- `try_cast("bemidji_blizzard")` is the only spend. Do not tax Fantasy Level (fireball still does `update_fantasy_level(15)` — do not copy that).
- HUD confirm on a client: `request_launch_blizzard_rpc` to peer 1; host validates.
- Two confirms same frame: sequential; second fails if mana < 30.
- Do not require dungeon exit.

## Acceptance

- **Given** locked unlock, **When** `launch_blizzard` runs with mana 100, **Then** it returns false, mana 100, `live_blizzard_count() == 0`.
- **Given** unlock and mana 10, **When** launched, **Then** false, mana 10, no pocket.
- **Given** unlock and mana 100 and a legal interior rect, **When** launched, **Then** true, mana 70, one live blizzard.
- **Given** unlock and mana 100 and a rect that clips to empty, **When** launched, **Then** false, mana 100.

## Notes

Pocket overlay string and expire behavior are T002. PP speed is T003. Do not fight the boss.
