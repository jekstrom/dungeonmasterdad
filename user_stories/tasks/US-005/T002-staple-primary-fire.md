# T002: Staple primary fire

**Story**: US-005  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T005

## Goal

Primary fire spawns a **host-validated** staple projectile in the player's facing/aim direction, consumes **exactly 1** staple, and destroys the projectile on first valid hit, wall, or max range.

## Files

- `player/player.gd` — primary-fire input; existing aim (`player/aim_cursor.tscn`)
- New staple projectile (suggested: `spells/` or `player/` scene) using `sprites/staple_projectile.png` (32×32 exists)
- Existing projectile-spawner pattern (fireball / `spells/fireball/`)
- Wall collision (map / dungeon walls); FR-008

## Requirements

- FR-002, FR-003, FR-008, AC1, edge: last staple
- Consume exactly one when the magazine has ammo. Fire on the last staple: one shot, magazine goes to 0.
- Travel facing/aim dir. Configurable damage (suggested 1) and max range.
- Destroy on first valid hurtbox, wall, or leaving max range. Do not pass through walls.
- Host validates spawn. Visual prediction is T009.

## Acceptance

- **Given** a Paper Pusher with at least one staple, **When** they press primary fire, **Then** a staple projectile spawns in the aim direction and the magazine decreases by one.
- **Given** the last staple, **When** they fire, **Then** exactly one projectile exists and the magazine is 0.
- **Given** a staple that hits a wall or exceeds max range, **When** it travels, **Then** it is destroyed and does not pass through.

## Notes

Empty click is T003. Hit/damage resolution is T004. Do not stretch the sword sheet (T008).
