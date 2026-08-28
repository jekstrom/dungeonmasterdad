# T005: Fireball spends mana on successful launch

**Story**: US-014  
**Status**: Done  
**Depends on**: T003  
**Parallel**: with T004

## Goal

Fireball still needs the `fireball` unlock **and** enough mana. Mana is spent when the spell actually launches, not when the reticle appears. Cancelling targeting refunds nothing because nothing was spent.

## Files

- `gui/dm/dm_hud.gd` — `_on_fireball_button_pressed` today: server + unlock, then `update_fantasy_level(15)` and `SignalBus.start_spell_cast`. Stop treating that as payment. Opening targeting may stay local for the DM; do **not** `try_cast` on button down.
- `dm/dm.gd` — `_unhandled_input` today emits `spell_cast` on `primary_click` while targeting, with no mana check. Host: `try_cast("fireball")` then emit `spell_cast` / clear reticle. On false: no projectile, mana unchanged; reticle may clear or stay — pick one and keep it (prefer clear so the DM is not stuck).
- `scripts/projectile_spawner.gd` — still spawns only on host `spell_cast` for `fireball`. Do not add a second mana check unless `spell_cast` can fire without `try_cast` (it must not).
- `test_harness/procedural_dungeon/us014_fireball_spend_test.gd` (+ `.tscn`) — targeting is free; confirm spends 15 / refuses locked, 0, and short mana.

## Requirements

- FR-003, FR-004, FR-005, FR-008, MR-001, AC1–AC3
- Unlock remains necessary and not sufficient (FR-008). HUD may hide the button until unlock (`on_dm_unlock`); server still checks.
- Edge case: the HUD **+15 Fantasy Level** grant is out of scope as a design change. Do not use it as a substitute for mana. Do not skip `try_cast` because FL was granted. Prefer not granting FL on a cancelled or refused cast (move a leftover +15 to successful launch if the line is still on the button).
- Targeting is not a world effect; refusing mana after targeting must not spawn `fireball_spell.tscn`.

## Acceptance

- **Given** fireball locked, **When** the DM confirms a target, **Then** no projectile and mana unchanged.
- **Given** fireball unlocked and mana 0, **When** they open targeting and click, **Then** no projectile and mana stays 0.
- **Given** unlocked and mana 10 (cost 15), **When** they confirm, **Then** no projectile and mana stays 10.
- **Given** unlocked and mana ≥ 15, **When** they confirm, **Then** mana decreases by 15 and one fireball spawn runs.
- **Given** unlocked and enough mana, **When** they open targeting and cancel without confirm, **Then** mana is unchanged.

## Notes

Blizzard targeting is US-017. Do not add a blizzard button. `try_cast("bemidji_blizzard")` is enough for the independent test’s “blizzard refuses at 0 mana.”
