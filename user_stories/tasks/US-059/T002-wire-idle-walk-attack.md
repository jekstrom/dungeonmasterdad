# T002: Wire idle, walk, and melee clips

**Story**: US-059  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

`dm.tscn` Sprite2D uses the new idle/walk/attack sheets. AnimationPlayer clips `{idle,walk,attack}_{down,side,up}` play 4 frames (`hframes = 4`, `vframes = 3` per texture). Left still flips side via `scale.x`.

## Files

- `dm/dm.tscn`
- `dm/dm.gd` (only if texture swap needs a helper)
- `dm/scripts/dm_idle_state.gd` / `dm_walk_state.gd` / `dm_attack_state.gd` — keep `update_animation("idle"|"walk"|"attack")`

## Requirements

- Live texture is **not** `PlayerSprite02.png`.
- Attack oneshot still finishes into idle; hurtbox pulse stays US-existing (do not retune damage or duration unless the new 4-frame clip length requires matching the existing ~0.28–0.32s window).
- South-foot sprite offset / y-sort must still read correctly.

## Acceptance

- **Given** the DM stands, walks, and melee-attacks in each facing, **When** a peer watches, **Then** they see the wizard staff clips, 4 frames, left = flipped side.
