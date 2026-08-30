# US-030 tasks: Inventory — active vs static rows

**Story**: [US-030.md](../../US-030.md)  
**Branch**: `030-inventory-rows`  
**Status**: Todo

One bag UI for **Paper Pushers and the DM**: top row **active** (usable, **Q E R T**), bottom row **static** (ingredients). Host stores **slots**, not a dict bag. Drag-swap stays in-row. Hold a hotkey to finish a channel. `player/inventory/inventory_ui.tscn` is already shared by `player_hud.tscn` and `dm_hud.tscn` — do **not** fork a DM inventory scene.

`ItemData.pickup_char` still gates who can pick an item up. This story adds a **row** flag and routes **use this cell**.

## Order

T001 (row flags on `.tres`) can run with T004 (InputMap rebind). Host slots (T002) need the flags so grants land in the right row. HUD layout (T003) can mock two rows but should bind to T002’s snapshot. Slot use (T005) needs T002 + T004. Channel hold (T006) needs T005. Drag-swap (T007) needs T002 + T003. Replication (T008) and the harness (T009) close.

`has_resources` / `consume_resources` / `get_item_count` MUST keep working so US-006 / US-007 / US-009 stay green — they sum **quantity by `resource_path`**, not slot index.

| ID | Task | Depends on | Parallel |
|---|---|---|---|
| [T001](T001-item-row-flags.md) | `ItemData` active/static + flag existing `.tres` | — | with T004 |
| [T002](T002-slotted-host-bag.md) | 4+4 host slots per peer; grant to row; full row drops | T001 | |
| [T003](T003-hud-rows.md) | Two rows, distinct colors, QERT labels, FOCUS_NONE | T002 | with T004 |
| [T004](T004-rebind-hotkeys.md) | Interact off E; slot actions Q E R T; drop colliding keys | — | with T001–T003 |
| [T005](T005-host-use-slot.md) | Hotkey/click uses **that cell** on the host | T002, T004 | |
| [T006](T006-hold-channel.md) | Channel items: hold to finish, release cancels | T005 | |
| [T007](T007-drag-swap.md) | Drag move/swap same row; reject cross-row | T002, T003 | with T005–T006 |
| [T008](T008-replicate-slots.md) | Owner HUD = host slots; late join; reject foreign swap | T002, T005, T007 | |
| [T009](T009-verification-harness.md) | Headless + play independent test | T003–T008 | |

## Out of scope (stay in other stories)

- Form fill **outcomes** and IRS file (US-009). T005/T006 only **start/hold** fill via the blank-form cell. Do not retune +15 / +50 RL.
- Create-form from paper (US-009). Paper is **active**: using its QERT cell creates a blank form. Dedicated create-form must not stay on F if interact is F.
- Factory / IRS **interact** (deposit/file). Stays the `interact` action after it leaves **E**.
- Office Max (US-010), gremlins (US-013).
- Drag-off-HUD world drop. Snap back to source cell.
- Keybinding options menu. Defaults Q E R T only.
- Changing `max_inv_slots` away from 8.

## Independent test (story)

As a PP or as the DM, pick up one active item and one static item that character can carry. They land top vs bottom. Top cells show Q E R T. Use the occupied active hotkey. Hold a channel item to complete; release early cancels. Same-row drag swaps. Cross-row drag refused. Colors differ.

## Suggested tunables (story)

| Knob | Default |
|---|---|
| Active cells | 4 (top), hotkeys Q E R T |
| Static cells | 4 (bottom) |
| `max_inv_slots` | 8 |
| Interact | rebind to **F** (was E) |
| US-009 create-form | leave F only if interact moves elsewhere; otherwise a third key — **not** QERT |
| US-009 fill_standard / fill_tax | **removed**; fill is hold-hotkey on the blank-form cell |
| Channel | `ItemData` flag; blank form is the existing channel |
| Cross-row drop | reject, no consume |
| Full row | `grant_item_or_drop` to world |
