# T001: Host-authoritative mana pool

**Story**: US-014  
**Status**: Done  
**Depends on**: none  
**Parallel**: with T002

## Goal

The DM has a spendable **mana** pool with current and max values. The host owns the numbers. Clients may display them. Nobody else authors them. Fantasy Level stays the zone-expansion resource and is not this pool.

## Files

- `_globals/dm_manager.gd` — `current_mana`, `max_mana` (default 100), `mana_changed(current, max)`, `add_mana(amount)`, `set_mana` / replicate RPC modeled on `update_fantasy_level` / `request_fantasy_level_incrase`.
- `scripts/multiplayer_spawner.gd` — `sync_global_state` today sends only `fantasy_level`; include current and max mana on join.
- `_globals/signal_bus.gd` — only if a bus signal is cleaner than `DmManager.mana_changed`; prefer the manager signal (same pattern as `fantasy_level_changed`).
- `test_harness/procedural_dungeon/us014_mana_pool_test.gd` (+ `.tscn`) — headless checks for start 0/100, clamp, replicate overwrite.

## Requirements

- FR-001, FR-007, AC4 (clamp), AC6 (values the HUD will read)
- Match start / `Lobby.host_started`: current mana **0** (story assumption). Reset on a new host so an autoload does not keep the last match.
- `add_mana` clamps to `[0, max_mana]`. Overflow is wasted, never stored as extra cans (edge case; consume is T006).
- Replication: host writes, `@rpc("authority", "call_local", "reliable")` (or equivalent) to peers. Clients must not expose a public setter that sticks.

## Acceptance

- **Given** a new match, **When** mana is read, **Then** current is 0 and max is 100 (or the configured max).
- **Given** current 90 and max 100, **When** `add_mana(25)` runs on the host, **Then** current is 100, not 115.
- **Given** the host changes mana, **When** a connected or late-joining DM client is synced, **Then** it sees the same current and max.
- **Given** a client, **When** it assigns `current_mana` locally, **Then** the host value is unchanged and the next replicate overwrites the client.

## Notes

Do not deduct mana here (T003). Do not change `fantasy_level` math. Do not build the HUD meter (T007). `multiplayer.is_server()` is true for `OfflineMultiplayerPeer`; use `Lobby.is_network_server()` when “the match host started” matters, same as other autoloads.
