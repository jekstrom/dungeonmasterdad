# US-031 tasks: Bemidji Blizzard spell

**Story**: [US-031.md](../../US-031.md)  
**Branch**: `031-bemidji-blizzard`  
**Status**: Todo

The DM casts **Bemidji Blizzard**: mana **30**, a **3×3** Fantasy pocket for **~8s**, Paper Pushers inside move at **50%**, factories whose origin is in the rect tick at **2×** interval. Unlock is US-017. Occupancy is US-003 T011 (walk, no push-out).

## Current code (read this first)

A first pass already lives under US-017 T005–T008. Do **not** rewrite it. This story **owns** the spell and closes gaps.

- Catalog: `dm/dm_ability_catalog.gd` `BEMIDJI_BLIZZARD` cost **30**, unlock `"bemidji_blizzard"`. `DmUnlocks.dm_unlocks["bemidji_blizzard"]` starts false.
- Cast: `gui/dm/dm_hud.gd` `_on_blizzard_button_pressed` → `SignalBus.start_spell_cast` → `dm/dm.gd` targeting (`spells/targeting.tscn`), confirm → `DmManager.request_launch_blizzard` / `launch_blizzard`.
- `launch_blizzard` clips via `FantasyZone.clip_pocket_rect`, `try_cast`, then `spawn_pocket(..., "blizzard")`. **Gap (FR-002):** if `spawn_pocket` returns −1 **after** `try_cast`, mana is spent with no pocket. Spend must happen only after a live pocket id.
- Slow: `DmManager.blizzard_slow_factor_at` / `_blizzard_effects`. `Player.get_move_speed()` multiplies `BASE_MOVE_SPEED`. Monsters and `dm.gd` do **not** use that factor — keep it that way.
- Factories: `Building.sync_blizzard_interval()` scales remaining time; `BLIZZARD_FACTORY_INTERVAL_FACTOR` 2.0. Ghost/destroyed skip (US-011).
- HUD: `gui/dm/dm_hud.tscn` uses `spells/blizzard/blizzard.png` + pressed; control hidden until unlock.
- Overlay: `FantasyZone` loads `sprites/blizzard_overlay.png` when pocket `overlay == "blizzard"`.
- Replication: `late_join_blizzard_snapshot` / `replicate_blizzard_state` / `sync_blizzard_to_peer`. Pockets also broadcast via US-003 claim sync.
- Tests: `us017_blizzard_cast_test.tscn`, `us017_blizzard_factory_test.tscn`, `us017_blizzard_hud_test.tscn`, `us017_blizzard_replicate_test.tscn`, `us017_blizzard_test.tscn`. Keep them **green**. New cases go in `us031_*`.

Do not spawn or fight the Baja Blast boss here. Tests call `DmUnlocks.unlock("bemidji_blizzard")` (or set the dict) and `DmManager.add_mana`.

## Order

T001 (atomic cast) first — it owns `launch_blizzard`. Pocket clip/expire (T002) is mostly there; close the spend-before-spawn leak with T001. PP slow (T003) and factory interval (T004) can run after T001. HUD (T005) is already wired; only fix if overlay/HUD fails T005. **Storm art** (T008: ground ice + falling snow/icicles) needs the live pocket (T002); it can run with T003–T005. Replication (T006) and the harness (T007) close.

T001 and T006 both edit `_globals/dm_manager.gd` — do not implement them in parallel. T003 is `player/player.gd` + `DmManager` slow query. T004 is `buildings/building.gd` (already has `sync_blizzard_interval`). T005 and T008 both touch `FantasyZone` overlay — T008 after T005 if one person is editing that file; otherwise T008 may replace the ground texture T005 already points at.

| ID | Task | Depends on | Parallel |
|---|---|---|---|
| [T001](T001-cast-gate.md) | Targeting + `try_cast`; no spend if pocket fails | US-014, US-017 unlock | |
| [T002](T002-fantasy-pocket.md) | 3×3 clipped Fantasy pocket, overlay `blizzard`, expire | T001, US-003 T004 | with T003, T004 |
| [T003](T003-pp-slow.md) | PP speed 50% in rect; leave restores; no monster/DM slow | T001 | with T002, T004 |
| [T004](T004-factory-interval.md) | Origin in rect: 2× interval; scale remaining; not reset | T001 | with T002, T003 |
| [T005](T005-hud-overlay.md) | HUD icons hidden until unlock; ice on live pocket cells | T002 | with T003, T004; before T008 if sharing `FantasyZone` |
| [T008](T008-blizzard-vfx-art.md) | Ground ice tile + falling snowflakes/icicles in the rect | T002 | with T003, T004; after T005 if sharing overlay |
| [T006](T006-replicate-late-join.md) | Host pocket, slow, timers; late join snapshot | T002–T004 | after T001 |
| [T007](T007-verification-harness.md) | Headless + play independent test | T001–T006, T008 | |

## Out of scope (stay in other stories)

- Boss spawn, combat, death unlock, Baja Blast can (US-017). Do not retune `baja_boss.gd`.
- Occupancy **rules** and T011 walk (US-003). Call `spawn_pocket` / `clip_pocket_rect`; do not re-add a zone wall.
- Tile drift (US-004). Ice overlay is this story; grass/sparkle drift is not.
- Mana pool, Dew, other ability costs (US-014). Cost stays 30.
- Fireball (US-018), cube (US-019), cozy (US-020).
- Goblin raids / salvage (US-011). Slowed factories still produce until destroyed.

## Independent test (story)

Unlock Blizzard without a boss. Mana ≥ 30. Cast on Reality home: 3×3 Fantasy pocket, **ice on the ground**, **snow/icicles falling**, PP 50% inside, factory 2× if origin in rect, no place, expire restores. Locked / short mana refuse.

## Suggested tunables (story)

| Knob | Default |
|---|---|
| Ability id | `bemidji_blizzard` |
| Mana cost | 30 |
| Unlock | `bemidji_blizzard` (US-017) |
| Duration | 8s |
| Pocket size | 3×3 cells |
| PP slow factor | 0.5 |
| Factory interval factor | 2.0 |
| Targeting | fireball confirm; rect, not circle |
| Overlay | `"blizzard"` → `sprites/blizzard_overlay.png` (T008: ice sheet + falling flakes) |
