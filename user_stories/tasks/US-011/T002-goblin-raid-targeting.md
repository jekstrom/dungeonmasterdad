# T002: Goblin raid targeting (factories, then unique buildings)

**Story**: US-011  
**Status**: Done  
**Depends on**: none  
**Parallel**: with T001; before T003 (same `goblin.tscn` / `enemy.gd`)

## Goal

A living **goblin** with no Paper Pusher in character-aggro range acquires an **enabled factory** and **moves toward it**. If there is no factory, it may acquire IRS / other enabled buildings. Ghosts are ignored. No damage yet.

## Files

- `monsters/enemy.gd` — `_aggro_candidates()` is DM + `"players"` only. Add `@export var raids_buildings: bool = false` (default **false** so skeleton, knight, Baja Blast stay off — FR-007). When true, after character candidates, include enabled raid buildings. Character candidates still use `screen_spot_range()`. Raid search is **not** screen-limited: enabled buildings under `building_root` / group `"buildings"` / `"factories"` + `"irs"`.
- `monsters/enemy.gd` — `_closest_aggro_candidate()` today picks the nearest candidate inside `screen_spot_range()`. Keep that for **characters**. For buildings: if any living character is in `screen_spot_range()`, that character wins (AC1 / AC4). Else prefer **factories** (`SmokeFactory` / `PaperFactory` / group `"factories"`) over other `Building`s, then nearest within that tier.
- `monsters/enemy.gd` — skip `is_ghost`, name `"ghost"`, `not is_operating()`, and (after T004) destroyed. Do not target a Building parented to a Player (ghost preview).
- `monsters/goblin.tscn` — set `raids_buildings = true`. Wire idle + wander `attack_state` → a new `aggro` child using `monsters/states/enemy_state_aggro.gd`, same node_paths pattern as `monsters/skeleton/skeleton.tscn` (`attack_state = NodePath("../aggro")`, aggro `wander_state = NodePath("../wander")`). Do **not** add a Hurtbox here (T003).
- `monsters/enemy_state_wander.gd` / `enemy_state_idle.gd` — already transition when `has_aggro_target()`. No change if goblin exports `attack_state`.
- `test_harness/procedural_dungeon/us011_raid_targeting_test.gd` (+ `.tscn`) — instance goblin + enabled factory in open space; after a few state-machine ticks the goblin’s `aggro_target` is the factory and it has moved closer. Ghost factory: goblin wanders, `aggro_target` is not the ghost. Factory + IRS: target is the factory. IRS only: target is the IRS. Factory + a `"players"` node inside `screen_spot_range()`: target is the player. Knight/skeleton `raids_buildings` is false / they do not pick the factory.

## Requirements

- FR-004, AC1, AC5, AC6, edge: no buildings → existing wander
- `aggro_faction` on goblin stays **PLAYERS** (1). Do not aggro the DM as a raid substitute.
- Chase is existing aggro: `direction_to(target.global_position) * run_speed`. Do **not** add `NavigationAgent2D`. Headless tests place goblin and factory with a clear line; stuck-on-walls is out of scope.
- `is_melee_close_to` still uses Chebyshev ≤ 1 **for characters**. Building melee range is T003.
- HUD gremlin currently instances `goblin.tscn` — those summons will raid. Do not retarget `spawn_gremlin` or add a goblin HUD button (US-013 / US-014).
- Knight.tscn also uses `enemy.gd`; leaving `raids_buildings` default false is the lockout. T005 asserts it.

## Acceptance

- **Given** an enabled smoke or paper factory and a goblin with no player in `screen_spot_range()`, **When** idle/wander process, **Then** `aggro_target` is that factory and the goblin moves closer.
- **Given** a ghost factory only, **When** the goblin searches, **Then** it does not acquire it and keeps wandering.
- **Given** an enabled factory and an enabled IRS, **When** the goblin searches, **Then** it acquires the factory.
- **Given** only an enabled IRS, **When** the goblin searches, **Then** it acquires the IRS.
- **Given** a Paper Pusher in `screen_spot_range()` while a factory exists, **When** the goblin searches, **Then** `aggro_target` is the player (raid yields).
- **Given** no enabled buildings and no players in range, **When** the goblin processes, **Then** it stays in wander/idle like today.

## Notes

Do not apply HP here (T003). Do not destroy (T004). Skeleton aggro must still hunt the DM (`us001_skeleton_ban_test` / `us017_boss_aggro_test` patterns stay green). Goblins remain legal in Reality (`us001_reality_claim_test`: goblin must not be banned).
