# T007: Block Paper Pushers and DM at the cliff

**Story**: US-024  
**Status**: Todo  
**Depends on**: T006  
**Parallel**: no

## Goal

Neither role can path, dash, knockback, or spawn beyond the interior. Physics collision is the primary stop; the server still rejects or clamps any move that would leave the interior.

## Files

- `player/player.gd` / `dm/dm.gd` — optional client prediction clamp; server is source of truth
- `_globals/level_manager.gd` or map bounds — `clamp_world_to_interior(pos) -> Vector2`
- Physics: cliff collision (T002) on layers both CharacterBody2Ds mask
- Respawn: `PlayerManager.get_respawn_position()` currently uses Reality Zone center — must stay interior (T009)

## Requirements

- FR-003, MR-002
- Player types are always blocked (AC1).
- Knockback / blizzard / Fantasy push that would send a player off the map: clamp to the nearest interior walkable cell; do **not** kill them for leaving the map (edge case).

## Acceptance

- **Given** a match has started, **When** a Paper Pusher or DM tries to move past the interior, **Then** they occupy only the last walkable interior cell.
- **Given** a client predicts through the cliff, **When** the server resolves movement, **Then** the peer is still inside the interior.

## Notes

Do not use kill-on-void. Spawn placement is T009/T010; this task is live movement + displacement.
