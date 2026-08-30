# T003: Goblin melee damages buildings on the host

**Story**: US-011  
**Status**: Done  
**Depends on**: T001, T002  
**Parallel**: no (same `goblin.tscn`, `enemy.gd`, `building.gd` as T001/T002)

## Goal

When a goblin is in attack range of its factory (or unique-building) target and the aggro state pulses melee, the **host** subtracts goblin `Hurtbox.damage` from that building’s HP. Ghosts take no damage. HP does not go below 0 here in a way that despawns (T004 owns 0-HP).

## Files

- `monsters/goblin.tscn` — instance `res://hurtbox.tscn` like `skeleton.tscn`. `monitoring = false` by default; `EnemyStateAggro._update_melee` already toggles it. `Hurtbox.damage` default **1**. Mask must include the building Hitbox layer **and** player Hitbox layer **2** so goblins can still melee Paper Pushers once the Hurtbox exists (story: they were character-fighters; raid is in addition).
- `buildings/building.gd` — add a `Hitbox` child on smoke / paper / IRS scenes (`res://hitbox.tscn`) covering the existing `CollisionShape2D` hull (116×69 at `(5, -35)`). Connect `Damaged` to a host `take_damage(hurt_box)` on `Building`.
- `buildings/building.gd` — `take_damage`: `if not multiplayer.is_server(): return`. Ignore ghost / not `is_operating()`. Ignore hurtboxes whose owner is not a goblin / `raids_buildings` (player `AttackHurtbox` mask is **8**, same as goblin Hitbox — filtering is required or PP pencil will chip factories). Clamp HP ≥ 0. Refresh the T001 bar. Do **not** `queue_free` or swap rubble yet (T004).
- `monsters/enemy.gd` — `is_melee_close_to` currently requires Chebyshev ≤ 1 **and** `melee_range_px` (128). For `Building` targets, measure to `factory_origin()` (or the closest point on the body shape) and **drop the Chebyshev-1 gate** so a goblin on the north face of a 128×128 footprint can hit. Characters keep the existing gate.
- `monsters/states/enemy_state_aggro.gd` — already pulses Hurtbox when `can_melee_current_target()`. Confirm that works when `aggro_target` is a `Building`. Do not add a second attack state.
- `test_harness/procedural_dungeon/us011_goblin_melee_test.gd` (+ `.tscn`) — enable a smoke factory at 8 HP, place a goblin in melee range with no player nearby, tick the aggro SM until one pulse: HP is 7 on the host. Ghost factory: HP unchanged. Direct `take_damage` from a dummy non-goblin Hurtbox: HP unchanged. Client-like `hitpoints = 1` write must not be the authority path (T006 will harden replication; this test at least calls `take_damage` only when `multiplayer.is_server()`).

## Requirements

- FR-002, AC2, MR-001
- One pulse → one HP (damage 1). `melee_cooldown` stays **1.0**. Do not double-apply if Hurtbox overlaps two Hitbox shapes on the same building.
- Host-authoritative. `Hurtbox._area_entered` already calls `Hitbox.take_damage`; Building must no-op on clients.
- Staples must still skip buildings (`player/staple_projectile.gd` `_is_building`). `us005_combat_loadout_test.tscn` must stay green — if you add a real Hitbox to factories, that skip still has to work.
- Do not destroy at 0 in this task: leave HP at 0 with the building still `is_operating()` until T004, **or** call a `destroy()` stub that T004 fills. Prefer leaving HP at 0 and letting T004 hook the setter / `take_damage` when `hitpoints <= 0`.
- Same-frame production is T004. Same-frame deposit is T004.

## Acceptance

- **Given** a goblin in melee range of an enabled factory with no player in aggro range, **When** it completes one attack pulse, **Then** that factory’s HP is reduced by 1 on the server.
- **Given** a ghost factory, **When** a goblin Hurtbox overlaps it, **Then** HP is unchanged.
- **Given** a Paper Pusher `AttackHurtbox` or staple overlap, **When** the host resolves, **Then** building HP is unchanged.
- **Given** HP 8, **When** seven pulses apply, **Then** HP is 1 and the factory is still present and producing (T004 not required yet).

## Notes

Aggro-switch to a damaging Paper Pusher is existing character-range rules from T002 (AC4): if the PP is inside `screen_spot_range()`, they beat the factory; if they are not, raid continues. Do not add a separate “attacker threat” table.

Destroy / rubble / stop production is T004. Skeleton/knight/Baja proofs are T005.
