# T004: Replicate splash, knockback, and slick

**Story**: US-028  
**Status**: Done  
**Depends on**: T003  
**Parallel**: no

## Goal

Fountain period, charge/splash, knockback, slick spawn/expire, duration, and size are host-authoritative. Peers see the same fountain and the same slick.

## Files

- Fountain + slick from T001–T003
- Existing dungeon doodad / projectile replication pattern (`scripts/multiplayer_spawner.gd` or a dedicated MultiplayerSpawner). Do **not** auto-spawn tiles (ERR_BUG). Prefer host instantiate + RPC/sync of fountain cell and live slick rect like generated doodads / blizzard pocket remaining time

## Requirements

- FR-006, MR-001, MR-002
- Duration/size configurable on the host; clients receive the live slick rect + remaining time.
- Late join: receive fountain cell and any live slick.
- Do not replicate particle RNG if a local splash VFX is enough, but the **slick rect, remaining time, and knockback outcome** MUST match.
- Do not replicate Jet. Do not create a zone pocket.

## Acceptance

- **Given** a host splash, **When** peers watch, **Then** they see the same splash, knockback, and dew slick.
- **Given** a late joiner on a live slick, **When** they spawn, **Then** they slide on the same rect.

## Notes

Do not add a Freeze Wave boss clip. Harness is T005.
