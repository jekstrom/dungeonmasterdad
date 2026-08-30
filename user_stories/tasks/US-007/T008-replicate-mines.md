# T008: Replicate mines, iron grants, and late join

**Story**: US-007  
**Status**: Todo  
**Depends on**: T004, T006  
**Parallel**: no

## Goal

Every peer, including a late joiner, sees the same mine set, the same active/depleted (and hits / remaining yields if visible), and the same world iron drops. The owning Paper Pusher's **inventory metal** matches the host. Clients cannot complete a harvest or fake a grant the host did not authorize.

## Files

- `doodads/mine.gd` — host RPC or `MultiplayerSynchronizer` for `hits_taken`, `yields_taken`, `is_depleted` (and regen remaining if needed). Pattern: `TreeDoodad.sync_harvest_state`.
- `_globals/level_manager.gd` — mine list on the map payload (`x`, `y`, plus `h` / `ylds` / `d` depleted), apply on join like `_apply_trees_from_payload`. Unique names `mine_%d_%d`.
- `_globals/player_manager.gd` — `update_client_inventory` already pushes owner HUD. Metal stacks ride that path after `grant_item_or_drop` and `consume_resources`.
- `scripts/pickup_spawner.gd` — host-only `on_item_drop` for overflow iron.
- `test_harness/procedural_dungeon/us007_replicate_test.gd` (+ `.tscn`) — host depletes or partial-hits a mine, payload to joiner matches; client local `hits_taken` write does not stick on host; inventory metal replicates to owner.

## Requirements

- FR-005, MR-001, MR-002
- All peers see depleted vs active after a yield that depletes the mine.
- Shared harvest progress: wood-style, one bar, no duplicate iron.
- Late join: mine cells, depleted flags, leftover hits/yields, uncleared metal pickups.
- Client log on join stays clean (`ERR_BUG` / `has_node` / invalid synchronizer).
- `_melee_swing_active` still expires on the host after a mine swing so client LMB staples work (US-006 server flag bug).

## Acceptance

- **Given** another peer is present, **When** a mine is depleted, **Then** all peers see depleted art/state and the same iron grant or drop.
- **Given** the host metal count changes, **When** the owning client is in session, **Then** their inventory matches.
- **Given** a late-joining client, **When** they receive the map, **Then** mine positions and depleted/active match the host.
- **Given** a client, **When** it fakes `hits_taken` or `add_item_to_inventory` metal, **Then** the host mine and inventories do not take the fake.

## Notes

Do not replicate every swing VFX. Ghost factory placement is unchanged.
