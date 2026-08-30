# T005: Interact-to-deposit wood at a paper factory

**Story**: US-006  
**Status**: Done  
**Depends on**: T001  
**Parallel**: after T001; before T006 (same `paper_factory.gd`)

## Goal

A Paper Pusher in range of an **enabled** paper factory **interacts** to move wood from their inventory into that factory's **wood buffer**. Deposit is explicit, not an auto-vacuum, so world piles can later be contested (US-013). Production is T006. `PlayerManager.interact_pressed` is currently commented out; do not depend on that dead signal.

## Files

- `buildings/buildables/paper_factory.gd` — host `stored_wood` (int, default 0). Export deposit range (suggested: factory footprint / ~64px from `factory_origin()`). Host RPC or host-called `try_deposit_wood(player_id)` : if ghost, fail; if player out of range, fail; if `has_resources` wood, `consume_resources` 1 wood and `stored_wood += 1`.
- `_globals/player_manager.gd` — `has_resources` / `consume_resources` already keyed by `resource_path`. After consume, drop inventory keys at quantity ≤ 0 so empty wood does not occupy a slot. Do not resurrect the commented `interact_pressed` as the authority path.
- `player/player.gd` / idle+walk `HandleInput` — on `"interact"`, owning client `rpc_id(1, ...)` a deposit request (or a generic interact that the factory answers). Server validates range and role (Paper Pusher only).
- `pickups/wood.tres` — the `resource_id` for has/consume (T001 path `res://pickups/wood.tres`).
- `test_harness/procedural_dungeon/us006_deposit_wood_test.gd` (+ `.tscn`) — grant wood, enable a factory, deposit in range: inventory −1, `stored_wood` +1; out of range / ghost / no wood / DM: no change.

## Requirements

- FR-004, FR-008, story assumption: interact-to-deposit is the default
- **One wood per successful interact** (not dump-all). Repeat interact to fill the buffer.
- Optional cap on `stored_wood` (suggested ≥ 1 cycle; a small cap like 5 is fine). Overflow interact fails and leaves inventory unchanged.
- Ghost factories (`is_ghost`) do not accept wood.
- Disconnect after deposit: wood stays on the **factory**, not in the leaving player's inventory. Do not delete it.
- Do not auto-pull wood from the ground. World wood stays an `ItemPickup` until a player picks it up (gremlins later).
- Do not consume smoke or emit paper here (T006).
- Host-authoritative. Clients must not increment `stored_wood` in a way that sticks.

## Acceptance

- **Given** a Paper Pusher with ≥1 wood in range of an enabled paper factory, **When** they interact, **Then** inventory wood decreases by 1 and that factory's `stored_wood` increases by 1.
- **Given** the player is out of range or the factory is a ghost, **When** they interact, **Then** inventory and `stored_wood` are unchanged.
- **Given** no wood in inventory, **When** they interact at a factory, **Then** `stored_wood` is unchanged.
- **Given** a deposited factory and the depositing peer disconnects, **When** `stored_wood` is read on the host, **Then** it is still there.

## Notes

Production interval is T006. Keep blizzard `sync_blizzard_interval()` on the factory (US-017 T006) — this task only adds a buffer and deposit. Do not use `PlayerManager.max_paper_amt` / a global paper pool.
