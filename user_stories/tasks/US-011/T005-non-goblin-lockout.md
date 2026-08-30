# T005: Only goblins destroy buildings

**Story**: US-011  
**Status**: Done  
**Depends on**: T003  
**Parallel**: with T004

## Goal

**Skeletons, knightlings, Baja Blast, staples, and Paper Pusher melee** must not reduce building HP. Goblin raid is the only building-damage path unless a later story says otherwise.

## Files

- `buildings/building.gd` — `take_damage` already filters non-`raids_buildings` / non-goblin hurtboxes (T003). This task **proves** it and closes holes: fireball is a body exploder (`spells/fireball/fireball_spell.gd`) and must not call building `take_damage`. Carbonated jet / Baja spit follow their own hit paths — they must not chip factories.
- `monsters/skeleton/skeleton.tscn` / `monsters/knight/knight.tscn` / `monsters/baja_boss.tscn` — `raids_buildings` stays default **false**. Do not wire their Hurtboxes onto the building Hitbox layer as a targeting change. If a skeleton Hurtbox physically overlaps a factory Hitbox, HP must still not change.
- `player/staple_projectile.gd` — already returns on `_is_building`. Keep that. Do not “fix” it to damage factories.
- `player/player.tscn` `AttackHurtbox` (`collision_mask = 8`) — pencil melee hits goblin Hitboxes. Building Hitbox must not take that damage (T003 filter).
- `test_harness/procedural_dungeon/us011_non_goblin_lockout_test.gd` (+ `.tscn`) — enabled paper factory at 12 HP. Skeleton Hurtbox pulse / `take_damage` from a skeleton: HP 12. Knight dummy hurtbox: HP 12. Staple spawn overlapping the factory (reuse `us005_combat_loadout_test` building skip): HP 12, `_building_damage == 0`. Player AttackHurtbox overlap: HP 12. Goblin pulse still deals 1 (regression on T003). `Enemy.raids_buildings` is false on instantiated skeleton and knight.

Keep `test_harness/procedural_dungeon/us005_combat_loadout_test.tscn` green.

## Requirements

- FR-007, AC4 (PP fights the goblin, not the building)
- Do not make skeletons raid if they wander into Reality (they despawn there anyway — US-001). Still assert their `take_damage` no-op on a factory in a headless scene without zone bans.
- Do not implement knightling execute (US-012) or gremlin steal (US-013).
- HUD gremlin = `goblin.tscn` **is** allowed to raid until US-013 swaps the packed scene. That is not a T005 fail.

## Acceptance

- **Given** an enabled factory, **When** a skeleton, knight, staple, or Paper Pusher melee overlaps it, **Then** HP is unchanged.
- **Given** the same factory, **When** a goblin melee pulse applies, **Then** HP drops by 1.
- **Given** `monsters/knight/knight.tscn` and `monsters/skeleton/skeleton.tscn`, **When** instanced, **Then** `raids_buildings` is false.

## Notes

Baja Blast boss combat stays US-017. If a boss blast already uses Hurtbox→Hitbox, include it in the no-op list. Do not retune staple magazine or pencil sheets (US-005).
