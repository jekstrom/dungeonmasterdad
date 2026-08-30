# US-006 tasks: Harvest wood from trees for paper

**Story**: [US-006.md](../../US-006.md)  
**Branch**: `006-harvest-wood`  
**Status**: Headless complete; play pass not run

Paper Pushers harvest **trees** for **wood**, deposit that wood at a **paper factory**, and the factory consumes wood plus smoke to emit **paper**. Trees today are `TreeDoodad` visuals only. `PaperFactory` already burns smoke and raises Reality Level (US-008); it does not take wood or emit a paper item.

## Order

Do T001 and T002 first; they do not need each other. Yield (T003) needs both the items and harvest hits. Lockouts (T004) need the harvest action. Deposit (T005) only needs wood in inventory. Production (T006) needs the factory wood buffer. Replication (T007) and the harness (T008) close the story.

T005 and T006 both edit `buildings/buildables/paper_factory.gd` — do not implement them in parallel; T006 after T005 is safest.

| ID | Task | Depends on | Parallel |
|---|---|---|---|
| [T001](T001-wood-paper-items.md) | Wood and paper `ItemData` + pickup art | — | with T002 |
| [T002](T002-tree-harvest-hits.md) | Host-validated harvest hits on living trees | — | with T001 |
| [T003](T003-wood-yield-stump.md) | Yield wood (grant or drop) + stump; one yield | T001, T002 | with T004 |
| [T004](T004-harvest-lockouts.md) | No harvest in Fantasy, under a building, or by the DM | T002 | with T003 |
| [T005](T005-deposit-wood.md) | Interact-to-deposit wood into a paper factory buffer | T001 | after T001; before T006 |
| [T006](T006-paper-production.md) | Factory needs wood + smoke; emit paper; no wood → no smoke spend | T005 | |
| [T007](T007-replicate-harvest.md) | Replicate tree state, grants/drops, factory I/O, owner inventory | T003, T006 | |
| [T008](T008-verification-harness.md) | Headless + play independent test | T003–T007 | |

## Out of scope (stay in other stories)

- Tree **scatter** on interior overworld cells (US-024 T012). This story harvests existing `TreeDoodad`s.
- Iron / mines (US-007). Do not add a mine node or spend wood as building `cost_item`.
- Reality Level amounts and the smoke-power rules (US-008). Keep paper factory `update_reality_level(10)` and `smoke_consume_amt` 3 unless US-008 changes them. Do not raise Reality when wood is missing.
- Forms, tax, IRS (US-009). Paper is an item only.
- Gremlin theft of world piles (US-013). Interact-to-deposit is the default **so** gremlins can contest piles later; do not implement gremlin carry here.
- Office Max / staple restock (US-010). Harvest is not a restock.
- Building combat damage (US-011).
- Fantasy occupancy / PP walk (US-003 T011). Paper Pushers **may walk** Fantasy; harvest still must not work there (T004). Do not re-add a zone wall.

## Independent test (story)

Find a tree, harvest it, receive wood in inventory. Deliver wood to a paper factory that also has smoke (US-008). Factory consumes wood and produces paper in inventory or as a world pickup the harvester can take.

## Suggested tunables (story)

| Knob | Default |
|---|---|
| Harvest hits per tree | 3 |
| Wood per fully harvested tree | 3–6 (rolled on the host) |
| Wood consumed per paper cycle | 1 |
| Paper factory wood buffer | 5 |
| Smoke consumed per paper cycle | 3 (existing `smoke_consume_amt`; US-008) |
| Paper factory interval | 6s (3× the previous 2s) |
| Reality Level per successful paper cycle | +10 (existing; US-008) |
| Tree respawn | none (finite wood; optional long timer later) |
| Deposit | explicit interact (not auto-radius vacuum) |
