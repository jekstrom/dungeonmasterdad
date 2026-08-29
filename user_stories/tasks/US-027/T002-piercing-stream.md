# T002: Piercing neon syrup stream

**Story**: US-027  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: no

## Goal

Fire a **piercing high-velocity** stream of neon Baja syrup along the telegraphed line. Host-authoritative. **Hits the DM** in the dungeon. Not Freeze Wave. Not US-017 blast.

## Files

- New jet projectile/stream (not `baja_boss_blast.gd` hurtbox spit)
- DM hurtbox / dungeon combat damage path
- `monsters/baja_boss.gd`

## Requirements

- FR-002, FR-003, FR-004, AC2, AC3, AC4
- Piercing: does not stop on the first target.
- High velocity, thin linear, neon Baja teal — not ice, not a wide wave.
- Host resolves hits. Suggested damage configurable.
- Paper Pusher in the lane may be hit; do not wall or shove them (T011).

## Acceptance

- **Given** the telegraph completes, **When** the stream fires, **Then** it travels the lane at high speed and pierces.
- **Given** the stream overlaps the DM, **When** the host resolves, **Then** the DM is hit.
- **Given** US-017 blast or a Freeze Wave, **When** Jet plays, **Then** it uses a different scene/VFX/hit shape.

## Notes

Replication is T003. Do not collapse into an ice sheet (US-028).
