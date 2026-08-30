# US-011 tasks: Goblins raid and destroy factories

**Story**: [US-011.md](../../US-011.md)  
**Branch**: `011-goblin-factory-raids`  
**Status**: Headless complete; play pass not run

**Goblins** path to enabled **factories**, melee them, and at 0 HP tear them down so they stop producing. Unique buildings (IRS; Office Max when it exists) are valid fallback targets, not immune. Paper Pushers can kill the goblin first. Skeletons, knightlings, and staples do not do this.

## Current code (read this first)

The story context is slightly stale:

- `Building.hitpoints` already exists (`@export var hitpoints: int = 10`) but nothing reads it: no `max_hitpoints`, no `take_damage`, no bar, no 0-HP destroy. Factories and IRS are `StaticBody2D` under `building_root` (`playground.tscn` `Buildings` + `BuildingSpawner`).
- Ghosts are real: `Player.setup_building` instances a child named `"ghost"` with `set_ghost()` (collision disabled). Enabled buildings call `enable()`.
- `SmokeFactory` ticks `PlayerManager.add_smoke(1)` every 3s. `PaperFactory` consumes wood + smoke and emits paper (US-006); it does **not** currently raise Reality (US-008). `IrsBuilding` files tax forms. There is **no** Office Max scene (US-010).
- `monsters/goblin.tscn` uses `enemy.gd` directly. `aggro_faction = 1` (`PLAYERS`). It has a **Hitbox** (can be killed) but **no Hurtbox** and **no aggro/attack state**: idle ↔ wander ↔ stun only. `EnemyStateAggro` / `EnemyStateAttack` exist; **skeleton.tscn** is the wired reference (idle/wander `attack_state` → `aggro`, Hurtbox toggled on melee).
- Catalog spawn: `scripts/procedural_dungeon/monster_catalog.gd` `"goblin"` → `goblin.tscn`. HUD **gremlin** (`DmManager.spawn_gremlin` / `playground.tscn` `gremlin` export) currently instances the **same** scene. US-013 will split gremlins off; until then HUD summons raid. Do not add a second goblin HUD button.
- `Enemy._aggro_candidates()` is characters only (`DmManager.dm` and/or `"players"`). `is_melee_close_to` is distance ≤ `melee_range_px` **and** Chebyshev ≤ 1 on 128px cells.
- Staples already skip buildings (`player/staple_projectile.gd` `_is_building`). `us005_combat_loadout_test.tscn` asserts buildings take no staple damage. Keep that green.
- Rubble art is already on disk: `sprites/smoke_factory_rubble.png` (128×128), `sprites/paper_factory_rubble.png` (100×100). Do not regenerate.

## Order

Do T001 (HP + bar) and T002 (raid targeting) first; they do not need each other. Melee damage (T003) needs both a target and HP, and shares `goblin.tscn` / `enemy.gd` with T002 — T003 after T002. Destroy/rubble (T004) needs a working hit. Non-goblin lockout (T005) needs `Building.take_damage`. Replication (T006) and the harness (T007) close.

T001, T003, and T004 all edit `buildings/building.gd` — do not implement them in parallel. T002 and T003 both edit `monsters/goblin.tscn` and `monsters/enemy.gd` — T003 after T002.

| ID | Task | Depends on | Parallel |
|---|---|---|---|
| [T001](T001-building-hp.md) | Server-side building HP + visible bar | — | with T002 |
| [T002](T002-goblin-raid-targeting.md) | Goblin prefers factories, then unique buildings; skip ghosts | — | with T001; before T003 |
| [T003](T003-goblin-melee-buildings.md) | Goblin melee drops building HP on the host | T001, T002 | |
| [T004](T004-destroy-rubble.md) | 0 HP: stop production, drop collision, rubble, no refund | T003 | |
| [T005](T005-non-goblin-lockout.md) | Skeleton / knight / staple / PP melee cannot destroy buildings | T003 | with T004 |
| [T006](T006-replicate-building-hp.md) | Host HP, bar, rubble/despawn; late join; client cannot fake | T001, T004 | |
| [T007](T007-verification-harness.md) | Headless + play independent test | T003–T006 | |

## Out of scope (stay in other stories)

- Goblin / gremlin **spawn cost and unlock** (US-014 mana, US-016 knightling). Tests instance `goblin.tscn` directly.
- Knightling lethal combat (US-012). Knightlings hunt players, not buildings.
- Gremlin carry (US-013). Do not drop factory wood/iron as a consolation pile on destroy (refund nothing). HUD gremlin scene split is US-013.
- Office Max **building** (US-010). Set HP **16** only if that scene already exists; do not create it. Raid code should treat any enabled `Building` that is not a factory as unique-tier.
- Repair, rebuild discount, iron refund.
- NavigationAgent / A*. Use existing aggro chase (`direction_to` × speed). Tests place the goblin in open space next to the factory.
- Reality Level amounts and smoke-power rules (US-008). Destroy must stop **current** production (`add_smoke`, paper emit, wood consume). Do not add RL grants.
- Blizzard factory interval (US-017). Keep `sync_blizzard_interval()`; destroyed/ghost buildings must not tick.

## Independent test (story)

Place a smoke or paper factory. Spawn or walk a goblin into range. The goblin pathfinds to the factory, attacks it, factory HP drops, and at 0 HP the factory is removed and stops producing. A Paper Pusher can kill the goblin first and save the building.

## Suggested tunables (story)

| Knob | Default |
|---|---|
| Smoke factory HP | 8 |
| Paper factory HP | 12 |
| IRS HP | 20 |
| Office Max HP | 16 (US-010 scene only) |
| Goblin melee damage | 1 (`Hurtbox.damage`) |
| Goblin melee cooldown | 1.0s (existing `EnemyStateAggro`) |
| Character aggro range | existing `screen_spot_range()`; **beats** raid |
| Raid search | enabled buildings in `building_root` / groups; not screen-limited |
| Factory vs unique | smoke + paper first; IRS / other `Building`s if no factory |
| Ghost / destroyed | never a raid target |
| Refund | none (iron spent; `stored_wood` lost) |
| Rubble | smoke 128×128, paper 100×100; same sprite offset as the live factory |
