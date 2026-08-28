# T008: Monsters, projectiles, and other actors vs cliffs

**Story**: US-024  
**Status**: Done  
**Depends on**: T007  
**Parallel**: no

## Goal

Nothing roams the void. Document and implement one rule per actor kind: block, destroy, or clamp.

## Files

- `monsters/enemy.gd` / wander-aggro movement — collide with cliffs or clamp
- `scripts/projectile_spawner.gd` and fireball (and other projectiles) — collide with cliff and despawn
- Gremlin carry/loot pathing — cannot leave interior; drop inside (edge case)
- Any dash/charge (knight blitz) — clamp like players if it would exit

## Requirements

- AC2, FR-003
- Projectiles fired at a cliff: collide and despawn; MUST NOT continue into the void.
- Gremlin carrying loot to a cliff: drops inside the interior.

## Acceptance

- **Given** a monster would leave the interior, **When** movement is resolved, **Then** it is blocked or clamped; it does not path in empty space past the ring.
- **Given** a projectile whose trajectory hits a cliff, **When** it overlaps the cliff collider, **Then** it despawns and deals no further world travel.

## Notes

Per-type rules:

- Paper Pusher / DM: physics block + clamp (T007). Never kill for leaving the map.
- Enemy (skeleton, goblin/gremlin, knight including blitz): collide with cliff layer 16; clamp after `move_and_slide`. Stay inside; do not despawn.
- Gremlin loot carry: not implemented yet. When it exists, drop loot at the clamped interior position; the gremlin stays inside.
- Fireball (and other projectiles): collide with cliff layer 16 or leave the interior → explode/despawn at the last interior point. Do not travel into the void.

Players remain “always blocked” from T007.
