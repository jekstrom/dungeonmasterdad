# US-016 tasks: Dungeon power-ups — green Dew and dice

**Story**: [US-016.md](../../US-016.md)  
**Branch**: `016-dungeon-powerups`  
**Status**: Headless complete; play pass not run

The DM crawls the generated dungeon and finds **green Mt Dew** and **dice**. Dew still restores mana (US-014) and, on first pickup of the match, **unlocks knightling**. Dice raise **Fantasy Level**, which grows the Fantasy **home rectangle**. Paper Pushers cannot collect these pickups.

## Order

Do T001 and T002 first; they do not need the unlock gate. Catalog + `DmUnlocks` (T003) must land before Dew can grant the unlock (T004) and before the HUD hides the knight button (T005). Rectangle growth (T006) needs the dice effect. Late-join / match-reset (T007) needs the unlock key and HUD. The harness (T008) closes the story.

T004 and T005 both touch Dew / HUD unlock wiring — do not implement them in parallel on `gui/dm/dm_hud.gd`. T005 after T004 is safest if one person is editing the HUD; T003 can still finish first.

T003 **changes** US-014's "knightling unlock is empty" contract. Update those US-014 tests in T003 so `us014_run_harness.sh` still passes.

| ID | Task | Depends on | Parallel |
|---|---|---|---|
| [T001](T001-dungeon-pickup-placement.md) | Place Dew and dice in generated dungeon | — | with T002, T003 |
| [T002](T002-dice-fantasy-level.md) | d6 / d20 raise Fantasy Level | — | with T001, T003 |
| [T003](T003-knightling-unlock-gate.md) | `knightling` unlock in catalog + `DmUnlocks` | — | with T001, T002 |
| [T004](T004-dew-unlock-knightling.md) | First green Dew unlocks knightling | T003 | after T003; before T005 if sharing HUD |
| [T005](T005-knightling-hud.md) | Hide knight HUD until unlock; usable with mana | T003 | after T004 if sharing `dm_hud` |
| [T006](T006-fantasy-home-growth.md) | Dice FL grows Fantasy home rectangle | T002 | with T004, T005 |
| [T007](T007-unlock-replication.md) | Host-authoritative unlock + late join + match reset | T003, T005 | after T005 |
| [T008](T008-verification-harness.md) | Headless + play independent test | T001–T007 | |

## Out of scope (stay in other stories)

- Mana pool, Dew **mana** grant, and mana costs (US-014). Keep `ItemEffectRestoreMana` on green Dew. Do not spend Fantasy Level to summon.
- Knightling **lethal combat** (US-012). This story only gates the existing summon.
- Baja Blast boss / Bemidji Blizzard (US-017), Code Red dragon (US-018).
- Cube combining cans (US-019), Dad All Powerful (US-021).
- Fantasy occupancy / Paper Pusher push-out (US-003). T006 only grows the rectangle `Zone` already stores as `home_rect`.
- Dungeon exit / asymmetric start (US-015). Placement uses the existing generator walkable set.

## Independent test (story)

Run a dungeon: find a green Dew can as the DM, pick it up, mana rises (US-014) and knightling summon becomes available on the HUD. Find a die, pick it up, Fantasy Level increases and the Fantasy home rectangle grows. Paper Pushers cannot use these pickups.

## Suggested tunables (story)

| Knob | Default |
|---|---|
| Start-room green Dew | 4 (keep US-014) |
| Extra Dew outside start room | 0 (tunable; min total Dew is 1) |
| d6 count | 1 |
| d20 count | 1 |
| d6 Fantasy Level | +6 |
| d20 Fantasy Level | +20 |
| Knightling unlock id | `knightling` |
| Knightling mana cost | 40 (US-014; unchanged) |
