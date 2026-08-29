# T004: Host hit and damage

**Story**: US-005  
**Status**: Todo  
**Depends on**: T002  
**Parallel**: no

## Goal

Staple hit detection and damage are **host-authoritative**. Damage applies **once** to a valid hurtbox (monster, DM, other damageable). Buildings take **no** staple damage. Zone rules do **not** cancel combat.

## Files

- Staple projectile from T002
- Existing hurtbox / damage path (`attack_hurtbox` pattern, monster and DM hurtboxes)
- Buildings (US-001 placement) — ignore for staple damage

## Requirements

- FR-006, AC3, edge: building, overlapping zones
- First valid hit consumes the projectile and applies damage once (no double-hit).
- Buildings: no damage unless a later story says otherwise (US-011 is goblins, not staples).
- Aiming at the DM inside overlapping / either zone: combat is allowed. Zone occupancy (including US-003 T011 walk) does not cancel damage.

## Acceptance

- **Given** a staple overlaps a valid monster/DM/damageable hurtbox, **When** the host resolves the hit, **Then** damage is applied once and the projectile is consumed.
- **Given** a staple overlaps a building, **When** the host resolves, **Then** the building is undamaged and the projectile may still die on collision if it is a wall-like body.
- **Given** the target is in Reality or Fantasy claim, **When** the staple hits, **Then** damage still applies.

## Notes

Do not implement goblin factory raids (US-011). Visual prediction is T009.
