# T006: Replicate building HP, bar, and destroy

**Story**: US-011  
**Status**: Done  
**Depends on**: T001, T004  
**Parallel**: no

## Goal

Every peer, including a late joiner, sees the same building **HP**, **health bar**, and **destroyed/rubble** state. Clients cannot deal building damage or destroy a factory the host still has. Host remains source of truth.

## Files

- `buildings/buildables/smoke_factory.tscn` / `paper_factory.tscn` / `irs.tscn` `MultiplayerSynchronizer` — today: `position`, `CollisionShape2D:disabled`, `is_ghost`, timers, paper `stored_wood` / `cycle_paid`. Add `.:hitpoints` (and `.:destroyed` if it is a flag) with spawn + `REPLICATION_MODE_ON_CHANGE`, same pattern as `Enemy._configure_hp_replication()` (`NodePath(".:hp")`). Replicating `CollisionShape2D:disabled` already covers T004 collision. If rubble is a texture swap, replicate enough that peers swap too: a `destroyed` bool the `_ready`/setter uses to apply rubble locally is enough (do not replicate the Texture2D resource if a flag can drive it).
- `buildings/building.gd` — HP setter refreshes the bar on every peer (local visual). `take_damage` / `destroy()` remain `multiplayer.is_server()` only. `Lobby.is_network_server()` vs `multiplayer.is_server()`: host logic uses `multiplayer.is_server()` so `OfflineMultiplayerPeer` headless tests still run (same as factories’ `_process`).
- `scripts/building_spawner.gd` / `playground.tscn` `BuildingSpawner` — still auto-spawns **direct** children of `building_root`. In-place destroy must **not** `queue_free` the operating node if rubble must persist (T004). Do not add rubble as a second spawnable unless you chose spawn-rubble-then-free; prefer in-place + replicated flag. `_spawnable_scenes` already has smoke, paper, IRS.
- `gui/factory_status_hud.gd` — destroyed factories hide markers on every peer because `is_operating()` is false (replicated `is_ghost` / `destroyed` / disabled collision). Confirm; do not add an HP HUD on the PP/DM canvas.
- `test_harness/procedural_dungeon/us011_replicate_test.gd` (+ `.tscn`) — host `take_damage` then read `hitpoints` / bar ratio as if applied from a sync dict; client-side `hitpoints = 0` or `destroy()` call does not stick on the host; late-join payload / spawned replica of a destroyed factory is rubble, collision disabled, not producing. Optionally apply `apply_timer_sync_dict`-style dict if you add one for HP; otherwise assert SceneReplicationConfig contains `.:hitpoints`.

## Requirements

- FR-006, MR-001, MR-002, AC3 (peers)
- MR-002: rubble/collision-off in the same window as other replicated property changes (`ON_CHANGE`), not a second later RPC if the synchronizer already carries the flag.
- Client faking `hitpoints`, `destroyed`, or `add_smoke` after destroy must not produce on the host.
- Late join: an in-progress factory shows current HP (not always max); a destroyed factory shows rubble / not operating, not a full-HP producer.
- Ghosts still replicate `is_ghost` as today; they are not raid targets (T002).
- Client log on join stays clean (`ERR_BUG` / `has_node` / invalid synchronizer) for `BuildingSpawner`. Unique names on placed buildings already come from `add_child(..., true)`.

## Acceptance

- **Given** another peer is present, **When** a goblin chips a factory to 5 HP, **Then** that peer’s bar / `hitpoints` is 5.
- **Given** the host destroys a factory, **When** peers observe it, **Then** collision is gone, rubble (factories) is visible, and it does not produce.
- **Given** a late-joining client, **When** they receive state, **Then** they see the same HP or destroyed/rubble set as the host.
- **Given** a client, **When** it sets `hitpoints = 0` locally, **Then** the host factory is unchanged and still producing if it was.

## Notes

Do not spawn catalog buildings on the client. Do not replicate every melee VFX. `us006_replicate_test.tscn` (`stored_wood`) and `us017_blizzard_replicate_test.tscn` (factory timers) must stay green — adding HP properties must not drop `timer` / `stored_wood` / `cycle_paid`.
