# T004: Destroy at 0 HP — stop production, rubble, no refund

**Story**: US-011  
**Status**: Done  
**Depends on**: T003  
**Parallel**: with T005 (different files; T005 must not edit `building.gd`)

## Goal

When building HP reaches **0**, the host **immediately** stops production, disables collision, refunds nothing, and shows **rubble** for factories (same footprint / y-sort). Unique buildings stop counting as enabled so IRS can be rebuilt. Peers seeing the despawn/rubble is T006; this task makes the host world correct.

## Files

- `buildings/building.gd` — on host `hitpoints <= 0`: `destroy()`. Set a `destroyed` flag (or treat `hitpoints <= 0` as destroyed). `is_operating()` must become **false** (ghost **or** destroyed). `set_deferred` collision disabled; `collision_layer` / `collision_mask` 0. Hide the HP bar. Do **not** `PlayerManager.consume_resources` inverse — iron stays spent (FR-005). Do not `on_item_drop` wood/metal/paper from the building.
- `buildings/building.gd` / factory `_process` — **destruction wins the same frame as a production tick**. Check `is_operating()` / `destroyed` **before** `add_smoke`, `_try_begin_cycle`, `_complete_cycle`. If `PaperFactory.cycle_paid` is true, do **not** emit paper and do **not** refund the already-spent smoke.
- `buildings/buildables/paper_factory.gd` — `try_deposit_wood`: fail if destroyed / not `is_operating()` **before** `consume_resources`. Edge: deposit in the same frame as the last HP → wood stays in inventory.
- `buildings/buildables/smoke_factory.gd` — already returns on `is_ghost`; also return when destroyed / not operating so a last tick cannot `add_smoke`.
- `buildings/buildables/irs.gd` — `is_fileable()` / `_has_enabled_unique` must treat destroyed as not enabled. `_globals/building_manager.gd` `_has_enabled_unique` already skips ghosts; skip destroyed / `not is_operating()` too so a downed IRS frees the unique slot (US-009 T005 note).
- `gui/factory_status_hud.gd` — markers already key off `is_operating()` / `needs_wood()` / `is_producing_paper()`. Confirm a destroyed paper factory hides wood/paper/buffer icons. No new HUD.
- Rubble (art already on disk; do not redraw):
  - `sprites/smoke_factory_rubble.png` — **128×128**, match `sprites/smoke_factory.png`. Swap `Sprite2D.texture`; hide `Sprite2D2` / `Sprite2D3` smoke stacks. Keep `Sprite2D.position` `(0, -55)` so y-sort does not jump.
  - `sprites/paper_factory_rubble.png` — **100×100**, match `sprites/paper-sheet.png` frames. Swap `Sprite2D.texture`; keep `Sprite2D.position` `(1, -41)` and do not switch to 128×128.
- IRS has **no** rubble asset. Hide or leave the live sprite; collision still off; unique slot free. Optional `DestroySmoke` puff; do not invent IRS rubble.
- Prefer **in-place** destroy (same node under `building_root`) so y-sort debris stays and `BuildingSpawner` does not need a new spawnable. `queue_free` without rubble fails the smoke/paper art requirement.
- `test_harness/procedural_dungeon/us011_destroy_rubble_test.gd` (+ `.tscn`) — smoke factory: force HP 0 (or last `take_damage`) then `_process(interval)`: smoke unchanged, collision disabled, rubble texture, `is_operating()` false. Paper factory with `stored_wood` and smoke: destroy at 0, `_process(interval)`: no paper drop, wood not refunded to inventory, `stored_wood` may stay on the dead node but must not emit. Deposit after destroy: inventory wood unchanged. IRS destroy: `_has_enabled_unique` is false so a second IRS `can_place` would succeed (call the unique check; do not require a full placement). Ghost still ignored.

## Requirements

- FR-003, FR-005, AC3, edge: last HP vs production tick, edge: deposit during destroy
- Host-only destroy. Clients must not locally `queue_free` an operating factory.
- `sync_blizzard_interval()` already returns on `is_ghost`; treat destroyed the same so US-017 cannot retune a corpse.
- Trees / mines under a destroyed footprint become harvestable again only if their own overlap tests use `is_ghost` / `is_operating()` — confirm `doodads/tree.gd` / `doodads/mine.gd` skip destroyed buildings the same way they skip ghosts. If they only skip `is_ghost`, destroyed must count as ghost-like for overlap **or** those checks should use `is_operating()`.
- Do not refund iron. Do not auto-rebuild.

## Acceptance

- **Given** an enabled smoke factory at 1 HP, **When** a goblin lands the last hit, **Then** it is destroyed: no further `add_smoke`, collision disabled, rubble texture at the same origin, `is_operating()` false.
- **Given** an enabled paper factory that would complete a cycle this frame, **When** HP hits 0 in that frame, **Then** no paper is emitted, smoke is not spent again, and Reality is unchanged from this factory.
- **Given** a Paper Pusher with wood interacting in the same frame as destroy, **When** the host resolves, **Then** inventory wood is unchanged (deposit fails).
- **Given** a destroyed IRS, **When** uniqueness is queried, **Then** it does not block a new IRS.
- **Given** destroy, **When** inventories are read, **Then** no iron or wood was granted back.

## Notes

Replication of `destroyed` / sprite / collision to peers is T006. Do not implement Office Max rubble. Repair is out of scope.
