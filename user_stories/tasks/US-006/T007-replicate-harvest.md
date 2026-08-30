# T007: Replicate harvest, grants, and factory I/O

**Story**: US-006  
**Status**: Done  
**Depends on**: T003, T006  
**Parallel**: no

## Goal

Every peer, including a late joiner, sees the same living-tree / stump set, the same world wood and paper pickups, and the same factory wood buffer. The owning Paper Pusher's **inventory wood (and paper) counts** match the host on their HUD. Clients cannot complete a harvest or factory tick the host did not authorize.

## Files

- `doodads/tree.gd` — host RPC or `MultiplayerSynchronizer` for `hits_taken` / living vs stump (sprite region / stump texture). Scattered trees already replicate as a set in US-024 T014; **state after harvest** is this task (stump or despawn must reach peers and late join).
- `scripts/multiplayer_spawner.gd` / map sync — if trees are named uniquely under `ScatteredTrees`, include harvest state in the existing generated-tile / doodad payload **or** spawn stumps with unique names. Prefer unique names (`validate_node_name()`).
- `_globals/player_manager.gd` — `update_client_inventory.rpc_id(player_id, inventory)` already pushes the owner HUD (`SignalBus.inventory_updated`). Confirm wood and paper stacks ride that path after grant and after deposit/consume. Other peers do not need a foreign wood meter.
- `buildings/buildables/paper_factory.gd` — replicate `stored_wood` (and existing timer sync if a peer must show production). Drops already go through `PickupSpawner` / `on_item_drop` (host-only spawn).
- `gui/player/player_hud.gd` — optional: bind hidden `PaperCount` to the local inventory paper quantity (not a global `paper_amt`). Inventory slots alone satisfy MR-002 if they update live.
- `test_harness/procedural_dungeon/us006_replicate_test.gd` (+ `.tscn`) — host harvest then read tree/inventory on a simulated peer payload; client cannot increment `hits_taken` or `stored_wood` so it sticks; late-join dict includes stump + remaining wood buffer.

## Requirements

- FR-008, MR-001, MR-002, AC6
- All peers see the tree gone or as a stump after a completed harvest, and the same wood grant **or** the same world drop (not both, not a duplicate).
- Inventory replication is **owner-only** (existing pattern). Host remains source of truth.
- Client faking `hits_taken`, `stored_wood`, or `add_item_to_inventory` must not grant wood/paper on the host.
- Late join: living vs stump for trees still in the match; factory `stored_wood`; world pickups that have not been collected. In-flight melee pulse does not need catch-up.
- Client log on join stays clean (`ERR_BUG` / `has_node` / invalid synchronizer) for this spawn path.

## Acceptance

- **Given** another peer is present, **When** a tree is fully harvested, **Then** all peers see the stump/removal and exactly one wood grant or drop.
- **Given** the host inventory wood count changes, **When** the owning client is in session, **Then** their HUD/inventory matches the host.
- **Given** a late-joining client, **When** they receive state, **Then** they see the same stumps, factory wood buffer, and uncleared wood/paper pickups as the host.
- **Given** a client, **When** it tries to harvest or deposit without host validation, **Then** host trees, buffers, and inventories do not take the fake.

## Notes

Do not replicate every swing VFX unless it is already cheap. Empty-inventory full-drop uses the existing pickup spawner — do not spawn pickups on clients. Ghost factory visuals are unchanged.
