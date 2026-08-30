# T006: Host-authoritative spell state and late join

**Story**: US-031  
**Status**: Todo  
**Depends on**: T002, T003, T004  
**Parallel**: after T001 (same `dm_manager.gd`)

## Goal

Unlock, pocket, PP slow, and factory timers are **host-authored**. A late joiner gets current unlock, live pocket + remaining duration, matching slows, and scaled factory remaining.

## Files

- `_globals/dm_manager.gd` — `late_join_blizzard_snapshot`, `apply_late_join_blizzard_snapshot`, `replicate_blizzard_state`, `sync_blizzard_to_peer`, `pack_blizzard_slows`.
- `scripts/multiplayer_spawner.gd` — already `DmManager.sync_blizzard_to_peer(id)` on join. Keep it; do not drop unlock/mana sync when touching this.
- `_globals/DMUnlocks.gd` — unlock bit still US-017 / US-016 replication. Spell snapshot must not fight `host_started` reset.
- Factory `to_timer_sync_dict` / `apply_timer_sync_dict` already carry `factor` / `baseline` (US-011).
- `test_harness/procedural_dungeon/us017_blizzard_replicate_test.tscn` — keep green. Add `us031_replicate_test.gd` only if a join path is missing from that test.

## Requirements

- FR-009, MR-001, MR-002, MR-003, AC8
- Client cannot `launch_blizzard` successfully (`is_server()` false).
- All PP in the rect share the same factor (host query, not a per-client RNG).
- Late join: `bemidji_blizzard` true if unlocked; live rects; `expires_at` / remaining; factory `factor` 2 if origin in rect.
- Do not replicate particle RNG (US-026).
- Match reset / `Lobby.host_started`: blizzard effects clear (`_on_map_bounds_cleared_blizzard` / `clear_blizzard_effects`). Unlock reset stays US-016/US-017.

## Acceptance

- **Given** a host cast, **When** a peer is in session, **Then** they see the same pocket, slow, and factory timing.
- **Given** a client joins mid-blizzard, **When** `sync_blizzard_to_peer` runs, **Then** `live_blizzard_count`, rect, and PP factor match the host.
- **Given** a client, **When** it calls `launch_blizzard` locally, **Then** the host has no new pocket and mana is unchanged.

## Notes

Boss combat replication is US-017 T003. This task is the **spell** snapshot.
