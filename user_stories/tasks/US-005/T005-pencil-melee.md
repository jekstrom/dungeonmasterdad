# T005: Pencil melee

**Story**: US-005  
**Status**: Todo  
**Depends on**: none  
**Parallel**: with T002

## Goal

Melee is a **distinct huge pen/pencil** swing and hurtbox, dealing current `melee_damage`, spending **no staples**, and usable when the gun is empty.

## Files

- `player/player.gd` — existing `attack_hurtbox`, `melee_damage` (default 1)
- `player/sprites/player_pencil_melee.png` — exists (1024×192, 64×64; DOWN/LEFT/RIGHT/UP, idle×2 walk×4 swing×3)
- `sprites/melee_ink_slash.png` — exists (768×64, 12×64 frames)
- Do **not** stretch `PlayerSprite02.png` sword frames into a pen

## Requirements

- FR-004, FR-005, AC4, AC5
- Distinct animation and hurtbox from ranged. Pen vs pencil is a cosmetic/skin, not two damage models.
- Suggested melee damage stays at current `melee_damage` unless tuned.
- Empty magazine does not block melee.
- Harvest (US-006 / US-007) may later reuse melee input; this task is combat only.

## Acceptance

- **Given** a Paper Pusher in melee range of a valid target, **When** they press melee, **Then** they swing the huge pencil and deal `melee_damage` on a successful hurtbox overlap.
- **Given** melee is used, **When** the magazine is inspected, **Then** it is unchanged.
- **Given** the magazine is empty, **When** they press melee, **Then** the swing still happens.

## Notes

Same-frame vs fire is T006. Lockouts are T007. Ink slash is the swing VFX, not a projectile.
