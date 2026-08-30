# T007: Replicate forms, Reality, IRS, and late join

**Story**: US-009  
**Status**: Todo  
**Depends on**: T002, T004, T006  
**Parallel**: no

## Goal

Every peer sees the same Reality Level after a standard fill or tax file, the owning Paper Pusher’s form/paper counts match the host, and a late joiner sees at most one enabled IRS and existing buildings. Clients cannot grant Reality or duplicate a file the host did not accept.

## Files

- `_globals/player_manager.gd` — `update_reality_level` / `request_reality_level_increase` already replicate RL. `update_client_inventory` already pushes owner HUD after consume/grant. Confirm both run on create-form, fill complete, and file.
- `_globals/building_manager.gd` / `scripts/building_spawner.gd` / playground `BuildingSpawner` — IRS spawn on `building_root` with `add_child(..., true)` like factories so MultiplayerSpawner replicates the node. Unique check is host-only.
- `buildings/buildables/irs.tscn` — replicate `is_ghost` (and position) so clients agree `is_operating()` for the E hint.
- `player/player.gd` — fill progress RPC to the **owner** only if the bar is not host-local. Do not let a client `_complete_fill`.
- `scripts/pickup_spawner.gd` — host `on_item_drop` already spawns world pickups (overflow blank/filled/tax).
- `scripts/multiplayer_spawner.gd` `sync_global_state` — already sends `PlayerManager.reality_level` on join. No new field required if RL is the server value.
- `test_harness/procedural_dungeon/us009_replicate_test.gd` (+ `.tscn`) — host grants/fills/files; joiner payload or duplicated `PlayerManager.reality_level` / inventory counts match; client fake `update_reality_level` / `create_form` does not stick when `not is_server`; two IRS requests still one building.

## Requirements

- MR-001, MR-002, MR-003, FR-009
- After tax file, every peer’s Reality HUD matches (existing `reality_level_changed`).
- Late join: one IRS if the host has one; form items in world pickups still there; owner inventory on reconnect follows existing inventory sync (do not invent a new snapshot unless join currently drops items — if it does, say so and piggyback the existing path).
- Client log on join stays clean (`ERR_BUG` / `has_node` / invalid synchronizer) — add IRS to spawnable scenes (T005).
- Do not replicate every fill-bar tick to all peers.

## Acceptance

- **Given** the host files a tax form, **When** Reality is read, **Then** it increased by the tax amount on the host API the HUD uses.
- **Given** a client, **When** it calls `update_reality_level` or `create_form` locally, **Then** host Reality and inventories do not take the fake.
- **Given** an enabled IRS on the host, **When** a second place is requested, **Then** still one IRS.
- **Given** a late-join payload / second `LevelManager`+building_root applying the same spawned IRS, **When** counted, **Then** uniqueness still holds (one operating IRS).

## Notes

Fill channel in progress at disconnect: cancel and leave the blank (T003). Do not persist a half-fill across join. Ghost factory placement is unchanged.
