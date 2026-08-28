# T007: Unlock replication, late join, and match reset

**Story**: US-016  
**Status**: Done  
**Depends on**: T003, T005  
**Parallel**: after T005

## Goal

Knightling unlock is **host-authored** and the same for every peer that needs it. A late joiner sees the current unlock (HUD can show knight if they are the DM). A new match starts with knightling **locked** so an autoload does not keep the last match. Pickup consumption stays once-only (already in `ItemPickup.handle_pickup`).

## Files

- `_globals/DMUnlocks.gd` — reset the unlock map on `Lobby.host_started` (same idea as `DmManager._on_host_started` resetting mana). Default `knightling` (and existing keys) false. Use `Lobby.is_network_server()` when "the match host started" matters.
- `scripts/multiplayer_spawner.gd` — `sync_global_state` today sends fantasy level + mana only. Include unlock flags (at least `knightling` and `fireball`) so a joining peer is not stuck locked after the host already picked up Dew. RPC stays `@rpc("authority", "call_local", "reliable")` or a dedicated `sync_dm_unlocks` authority RPC.
- `_globals/signal_bus.gd` — only if a bus signal is cleaner than calling `on_dm_unlock` per key; prefer reusing `DmUnlocks.on_dm_unlock` so the HUD from T005 updates.
- `gui/dm/dm_hud.gd` — after replicated unlocks, knight button visibility must match T005 (`turn_on` reads the dict).
- `test_harness/procedural_dungeon/us016_unlock_replication_test.gd` (+ `.tscn`) — host unlock then apply replicated payload; client-local `dm_unlocks["knightling"] = true` does not stick if host still false; `host_started` clears the flag.

## Requirements

- FR-006, MR-001, MR-002
- Only the host calls `DmUnlocks.unlock`. `on_dm_unlock` is already `"authority", "call_local", "reliable"`.
- MR-001: the unlock is a DM ability flag; Paper Pusher peers may receive the replicated dict (harmless) but must not get a knight HUD. They see knightlings only when one is spawned.
- Double-collect: do not change pickup pooling except to confirm one Dew cannot unlock twice from two peers in the same frame (server `handle_pickup` disables the node first). No second task for this if T004's Paper Pusher test plus existing Dew consume cover it.
- New match / `Lobby.host_started`: `knightling` false, fireball false unless a later story says otherwise. Do not keep US-014 mana reset from clearing unlocks accidentally without listing them.
- Fantasy Level already replicates via `sync_global_state` / `request_fantasy_level_incrase`; include it in the late-join payload still (do not drop mana/FL when adding unlocks).

## Acceptance

- **Given** the host unlocked knightling, **When** a late peer is synced, **Then** that peer's `DmUnlocks.dm_unlocks["knightling"]` is true.
- **Given** a client, **When** it sets `dm_unlocks["knightling"] = true` locally while the host is locked, **Then** the host stays locked and the next host replicate overwrites the client.
- **Given** `Lobby.host_started` on the network server, **When** unlocks are read, **Then** knightling is false even if the previous match had unlocked it.
- **Given** two peers overlapping the same Dew, **When** the server resolves pickup, **Then** the can is consumed once and unlock/mana apply once.

## Notes

`multiplayer.is_server()` is true for `OfflineMultiplayerPeer`; headless tests that need "real host started" should emit `Lobby.host_started` or call the reset method directly. Do not spawn catalog pickups on the client. `MultiplayerSpawner` still only auto-replicates **direct** children of `spawn_path` — pickups go through `PickupSpawner`, not this RPC.
