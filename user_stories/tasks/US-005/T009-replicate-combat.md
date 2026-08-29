# T009: Replicate projectile, swing, and damage

**Story**: US-005  
**Status**: Todo  
**Depends on**: T002, T005  
**Parallel**: no

## Goal

Projectile spawns, melee swings, and damage outcomes replicate to all peers. Clients may predict visuals. A client **cannot** fire more staples than the server magazine allows.

## Files

- Existing projectile spawner replication (fireball pattern)
- `player/player.gd` melee + magazine (T001)
- MultiplayerSynchronizer / host RPC as used by other combat

## Requirements

- FR-006, MR-001, MR-002, MR-003, AC6
- Fire/melee input may originate on the owning client; host validates range, ammo, and hits.
- Predicted muzzle flash / projectile must reconcile: extra client shots that the server rejects do not consume extra server ammo and do not keep a live projectile.
- Late join: current magazine for the owner; in-flight staples follow existing projectile catch-up if the spawner already does that.

## Acceptance

- **Given** another peer is watching, **When** fire or melee is used, **Then** they see the same firing/swing and the same damage outcome.
- **Given** a client tries to fire faster than the server magazine, **When** the host validates, **Then** only server-legal shots exist and the client magazine cannot go below the server count by faking fire.

## Notes

Do not replicate empty-click audio to everyone unless it is already cheap and local-only is harder. Occupancy/zone state is not this task.
