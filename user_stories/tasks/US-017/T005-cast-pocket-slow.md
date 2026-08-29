# T005: Cast Fantasy pocket and PP slow

**Story**: US-017  
**Status**: Todo  
**Depends on**: T004, US-003 T004, US-014  
**Parallel**: with T006, T007

## Goal

Unlocked Bemidji Blizzard costs **~30 mana**, creates an **axis-aligned Fantasy pocket** (US-003) for **~8s**, and slows Paper Pusher move **~50%** while they are **in the rect**. PP occupancy follows **T011**: they walk Fantasy; **do not push out**. Buildings still cannot place. Skeletons allowed unless a Reality pocket covers the point.

## Files

- US-014 `try_cast("bemidji_blizzard")` in `_globals/dm_manager.gd`
- US-003 pocket create API (`zones/scripts/fantasy_claim.gd` / zone pocket contract)
- Fireball targeting pattern (`spells/fireball/`, `spells/targeting.tscn`) — ground rect, not a circle
- `player/player.gd` move speed — apply slow factor inside the rect only

## Requirements

- FR-003, FR-004, FR-005, FR-007, FR-008, AC4, AC5, AC6, AC8
- No unlock or short mana: no pocket, no slow, no spend.
- Pocket is clipped to map interior (US-003 / US-024). Duration configurable (default ~8s).
- PP stay in the pocket and are slowed while inside. Leaving the rect restores their speed even if the pocket is still live.
- Buildings: footprint intersecting the live Fantasy pocket rejects (US-003 T007). Existing buildings are not destroyed.
- Skeletons: allowed in the pocket unless Reality-claimed (US-001).
- Default: slow lasts the spell duration on the cast rect even if a newer Reality pocket later covers it (claim still follows newer pocket).
- Expire: remove pocket and restore PP speeds in the same tick (factory restore is T006).

## Acceptance

- **Given** unlock + enough mana, **When** the DM casts Bemidji Blizzard, **Then** ~30 mana is spent and an axis-aligned Fantasy pocket exists for ~8s.
- **Given** a Paper Pusher inside that rect, **When** they move, **Then** they are not pushed out and their speed is ~50%.
- **Given** a building placement in the pocket, **When** requested, **Then** it is rejected.
- **Given** the pocket expires, **When** occupancy and movement tick, **Then** the pocket is gone and PP speed is baseline.

## Notes

Factory interval is T006. HUD/overlay is T007. Do not implement cozy or cube.
