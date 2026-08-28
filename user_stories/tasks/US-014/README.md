# US-014 tasks: Mountain Dew cans as Dungeon Master mana

**Story**: [US-014.md](../../US-014.md)  
**Branch**: `014-dm-mana`  
**Status**: Headless complete; play pass not run

The DM spends a **mana** pool (not Fantasy Level) to cast and summon. Green Mt Dew restores mana. Zero or short mana refuses the action with no world effect.

## Order

Do T001–T002 first. `try_cast` (T003) needs the pool and the cost table. Summons (T004) and fireball confirm (T005) need `try_cast`. Dew (T006) and the HUD meter (T007) only need the pool. The harness (T008) closes the story.

T004 and T007 both edit `gui/dm/dm_hud.tscn` / `dm_hud.gd` — do not implement them in parallel; T007 after T004 is safest.

| ID | Task | Depends on | Parallel |
|---|---|---|---|
| [T001](T001-mana-pool.md) | Host-authoritative mana pool | — | with T002 |
| [T002](T002-ability-costs.md) | Ability mana cost + unlock catalog | — | with T001 |
| [T003](T003-try-cast.md) | Server `try_cast`: gate, deduct, no side effects on fail | T001, T002 | |
| [T004](T004-summon-spend.md) | Gremlin / knightling HUD spends mana | T003 | after T003; before T007 |
| [T005](T005-fireball-spend.md) | Fireball spends mana on successful launch | T003 | with T004 |
| [T006](T006-dew-pickup.md) | Green Mt Dew restores mana (DM-only) | T001 | with T002–T005 |
| [T007](T007-mana-hud.md) | DM HUD current / max mana meter | T001, T004 | |
| [T008](T008-verification-harness.md) | Headless + play independent test | T003–T007 | |

## Out of scope (stay in other stories)

- Knightling **unlock** on first green Dew (US-016). This story only charges mana for the summon. Do not add or grant a `knightling` unlock here; leave the knight button summonable when mana is enough.
- Bemidji Blizzard **spell body**, HUD button, and Baja Blast boss (US-017). Register cost `30` so `try_cast("bemidji_blizzard")` refuses at 0 mana / without unlock.
- Dad All Powerful form (US-021) and cube recipe (US-019). Register cost `0` (US-021: activation at 0 mana is allowed once unlocked).
- Combining cans in the tube (US-019).
- Spell VFX besides existing fireball.

## Independent test (story)

Start the DM at 0 mana: fireball, gremlin, knight, blizzard all refuse. Pick up a green Mt Dew can: mana increases. Cast a spell: mana decreases by its cost and the spell happens. Try again at 0: refuse.

## Suggested tunables (story)

| Knob | Default |
|---|---|
| Max mana | 100 |
| Match start mana | 0 |
| Green Dew restore | +25 |
| Gremlin | 20 (no unlock) |
| Knightling | 40 (unlock is US-016; not gated here) |
| Fireball | 15 (still requires `fireball` unlock) |
| Bemidji Blizzard | 30 (requires future `bemidji_blizzard` unlock) |
| Dad All Powerful | 0 (requires future unlock; US-021) |
