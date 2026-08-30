# US-009 tasks: Forms, tax forms, and the IRS

**Story**: [US-009.md](../../US-009.md)  
**Branch**: `009-forms-irs`  
**Status**: Todo

Paper Pushers turn **paper** (US-006) into **blank forms**, fill them in the field, and file **tax forms** at a unique **IRS** building. Paperwork is the strong Reality loop: a filed tax form must raise Reality **more** than one paper-factory cycle (`PaperFactory._complete_cycle` currently calls `PlayerManager.update_reality_level(10)`).

Art is already on disk. Do **not** regenerate it unless a file is missing: `pickups/forms/blank_form.png`, `filled_form.png`, `tax_form.png` (32×32); `sprites/irs_building.png` (128×128); `sprites/irs_icon.png` / `irs_icon_pressed.png` (32×32). There are **no** form `.tres` or IRS building scenes yet.

## Order

T001 (form items) can run with T005 (IRS scene) — they do not share files. Create-form (T002) needs the blank item. Fill channel (T003) needs blank + filled/tax items. Fill outcomes (T004) need a successful channel. IRS placement (T005) is independent of fill. Filing (T006) needs a tax form in inventory and an enabled IRS. Replication (T007) and the harness (T008) close.

T003 and T004 both complete a fill on the host — implement T004 after T003 on the same complete path. T006 extends `Player.try_interact` the same way US-006 deposit did; do not steal factory E when a tax file is not possible.

| ID | Task | Depends on | Parallel |
|---|---|---|---|
| [T001](T001-form-items.md) | Blank / filled / tax `ItemData`; database load | — | with T005 |
| [T002](T002-create-form.md) | 1 paper → 1 blank form, host-validated | T001 | |
| [T003](T003-fill-channel.md) | Stand-still channel; type chosen at start; interrupt safe | T001 | after T001 |
| [T004](T004-fill-outcomes.md) | Standard complete → +RL; tax complete → no RL | T003 | |
| [T005](T005-irs-building.md) | IRS scene, iron cost, HUD place, max one enabled | — | with T001–T004 |
| [T006](T006-file-tax.md) | E at enabled IRS consumes tax form, +tax RL | T004, T005 | |
| [T007](T007-replicate-forms.md) | Inventory, RL, IRS uniqueness, late join | T002, T004, T006 | |
| [T008](T008-verification-harness.md) | Headless + play independent test | T002–T007 | |

## Out of scope (stay in other stories)

- Paper factory production and its **+10** Reality tick (US-006 / US-008). Do not retune `update_reality_level(10)` or smoke costs here. Tax file must stay **strictly larger** than that 10.
- Office Max (US-010). Different unique building. Do not create forms at Office Max. Do not restock staples at the IRS.
- Gremlin carry (US-013). Form drops use existing `SignalBus.on_item_drop` / `ItemPickup` so gremlins can contest them later.
- Building combat damage (US-011). If an IRS is freed, uniqueness should allow a rebuild; do not implement goblin attacks here.
- Iron harvest (US-007). IRS **costs** `metal.tres`; do not mine in this story.
- Wood / trees (US-006). Paper is an inventory input only.

## Independent test (story)

Produce paper, convert it to a blank form, fill it. A standard filled form grants some Reality. A filled tax form grants nothing until delivered to an IRS building, then grants a large Reality spike larger than one paper-factory cycle.

## Suggested tunables (story)

| Knob | Default |
|---|---|
| Paper → blank | 1:1 |
| Standard fill channel | 3s, stand still |
| Tax fill channel | 6s, stand still |
| Standard complete Reality | +15 |
| Tax file Reality | +50 |
| Paper factory cycle Reality | +10 (existing; do not change) |
| IRS `cost_item` | `res://pickups/metal.tres` |
| IRS `cost_qty` | 3 (same as factories) |
| IRS uniqueness | max **one enabled** (non-ghost) per match |
| File / create range | ~64px like factory deposit |
| Convert / fill / file | host-authoritative; Paper Pusher only |
