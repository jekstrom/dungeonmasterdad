# T003: Wire cast clips during targeting

**Story**: US-059  
**Status**: Todo  
**Depends on**: T001, T002  
**Owner**: Gameplay

## Goal

While a spell reticle is live, the DM plays `cast_down` / `cast_side` / `cast_up` from `dm_cast.png` (d20). When targeting ends, idle or walk resumes.

## Files

- `dm/dm.gd` (`setup_targeting`, `_clear_targeting`, aim-facing while targeting)
- `dm/dm.tscn` AnimationPlayer — add `cast_*`

## Requirements

- FR-004. Do not change mana, unlocks, or projectile VFX.
- Melee stays blocked while targeting (`wants_melee_attack`).
- Facing follows aim during cast the same way idle/walk already follow the mouse.

## Acceptance

- **Given** the DM opens fireball or blizzard targeting, **When** the reticle is up, **Then** the body is the cast sheet with the d20, correct facing.
- **Given** targeting confirms or cancels, **When** the DM is still, **Then** idle (staff) plays again.
