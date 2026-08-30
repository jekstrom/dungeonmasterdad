# T008: Replicate slot layout to the owner

**Story**: US-030  
**Status**: Todo  
**Depends on**: T002, T005, T007  
**Parallel**: no

## Goal

The owning client’s HUD matches the host’s 8 slots after grant, use, and swap. Other peers do not get that bag. A late-joining owner receives the **slotted** snapshot, not a reshuffled dict. Foreign `use_active_slot` / `swap_slots` is rejected.

## Files

- `_globals/player_manager.gd` — `update_client_slots.rpc_id(owner, snapshot)` (or an extended inventory RPC). Snapshot: two arrays of `{path, qty}` / null. `local_inventory` for `carried_count` can be derived by summing paths so factory E-hints still work.
- `scripts/multiplayer_spawner.gd` join sync — if inventory is already sent on join, send **slots** not dict keys. DM peer included.
- `player/inventory/player_inventory.gd` — apply snapshot by index; do not pack left.
- `test_harness/procedural_dungeon/us030_replicate_slots_test.gd` (+ `.tscn`) — host places blank in active 2 and wood in static 1; snapshot lists those indices; `use_active_slot` / `swap_slots` for another peer_id fails; client-only `ItemData.use()` does not change host qty.

## Requirements

- MR-001, MR-002, MR-003, FR-010
- Owner-only HUD. Do not broadcast bags to every peer.
- Late join must not reorder QERT contents.

## Acceptance

- **Given** a blank in active slot 2 on the host, **When** the owner snapshot is applied, **Then** HUD cell 2 is the blank (not packed to slot 0).
- **Given** peer 2, **When** they request swap on peer 1’s slots, **Then** peer 1’s slots are unchanged.
- **Given** a client local `use()` decrement, **When** the host count is read, **Then** it is unchanged.

## Notes

Fill-bar ticks stay owner-local (US-009). Do not replicate every drag preview frame.
