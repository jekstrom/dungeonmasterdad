# US-007 tasks: Harvest iron from mines to build

**Story**: [US-007.md](../../US-007.md)  
**Branch**: `007-harvest-iron`  
**Status**: Todo

Paper Pushers harvest **mines** for **iron** (existing `pickups/metal.tres`) and spend it as building `cost_item`. Harvest **interaction matches US-006 trees**: Space / pencil melee, host-validated `Hitbox` hits, shared progress, `PlayerManager.grant_item_or_drop`, local SPACE hint only when a yield is actually possible.

Mines are **repeatable** harvest nodes. They are not destroyed by one yield. After enough yields they **deplete**, then optionally **regenerate**.

## Order

T001 (iron item + building cost wiring) can run with T002 (mine doodad). Harvest hits (T003) need the mine scene. Yield / deplete / regen (T004) need hits + iron. Lockouts (T005) need hits. Map placement (T006) needs the doodad. Building spend (T007) only needs iron in inventory. Replication (T008) and the harness (T009) close.

T003 and T005 both edit mine harvest gates — T005 after T003 if sharing `doodads/mine.gd`. T006 places mines; T003 tests may instance a mine without the scatter.

| ID | Task | Depends on | Parallel |
|---|---|---|---|
| [T001](T001-iron-item-cost.md) | Iron is `metal.tres`; factories cost that item | — | with T002 |
| [T002](T002-mine-doodad.md) | Mine scene, active/depleted art, harvest Hitbox | — | with T001 |
| [T003](T003-mine-harvest-hits.md) | Host melee harvest hits; SPACE hint like trees | T002 | |
| [T004](T004-iron-yield-deplete.md) | Yield iron; deplete after N yields; optional regen | T001, T003 | with T005 |
| [T005](T005-mine-lockouts.md) | No harvest in Fantasy, under a building, or by the DM | T003 | with T004 |
| [T006](T006-mine-placement.md) | Place ≥1 mine on eligible overworld cells | T002 | with T003–T005 |
| [T007](T007-building-iron-cost.md) | Place building: enough iron deducted atomically; too little rejects | T001 | with T003–T006 |
| [T008](T008-replicate-mines.md) | Replicate mine progress/depleted; owner iron HUD; late join | T004, T006 | |
| [T009](T009-verification-harness.md) | Headless + play independent test | T003–T008 | |

## Out of scope (stay in other stories)

- Wood / paper / factory deposit (US-006). Do not spend iron as paper-factory input.
- Reality Level and smoke rates (US-008).
- Forms / IRS (US-009). IRS still costs iron unless that story marks it free.
- Office Max (US-010). Also costs iron unless marked free.
- Gremlin carry of dropped iron (US-013). Drops use the existing world pickup path so gremlins can contest them later.
- Building combat damage (US-011).
- Tree scatter (US-024 T012). Mines get their own placement (T006); do not replace the forest.

## Independent test (story)

Locate a mine, harvest it, receive iron. Spend that iron on a legal building placement and confirm the cost is deducted and the building appears.

## Suggested tunables (story)

| Knob | Default |
|---|---|
| Hits per iron yield | 4 |
| Iron per yield | 1 |
| Yields before deplete | 5 |
| Regen cooldown | >0 (configurable); **0 = stay depleted** |
| Mines per match | ≥1 (suggested 2–4) |
| Building `cost_item` | `res://pickups/metal.tres` |
| Smoke / paper factory `cost_qty` | 3 (existing) |
| Harvest input | Space / pencil melee (US-006) |
