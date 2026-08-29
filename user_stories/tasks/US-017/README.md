# US-017 tasks: Baja Blast boss unlocks Bemidji Blizzard

**Story**: [US-017.md](../../US-017.md)  
**Branch**: `017-baja-blast-blizzard`  
**Status**: Todo

One Baja Blast boss at the dungeon **exit**. Death unlocks `bemidji_blizzard` and grants the can. Cast plants a US-003 Fantasy pocket (~8s), slows PP move ~50% in the rect, and doubles factory intervals. Paper Pushers **walk** the pocket (US-003 T011). No push-out.

## Order

Spawn (T001) first. Sheet (T002) and combat (T003) can overlap after spawn exists. Unlock (T004) needs death. Cast pocket + slow (T005) needs unlock + US-003 T004. Factory slow (T006) and HUD (T007) can run with T005. Replication (T008) and the harness (T009) close.

| ID | Task | Depends on | Parallel |
|---|---|---|---|
| [T001](T001-spawn-exit-boss.md) | One boss at dungeon end/exit; skip-boss flag | dungeon gen | |
| [T002](T002-boss-sheet.md) | Wire 128×128 3-dir sheet; south placeholder OK | T001 | with T003 |
| [T003](T003-host-boss-combat.md) | Host HP, wander, attack, blast, die | T001 | with T002 |
| [T004](T004-death-unlock-can.md) | Death unlocks `bemidji_blizzard` + grants can | T003 | |
| [T005](T005-cast-pocket-slow.md) | Cast: mana ~30, Fantasy pocket, PP walk T011, 50% slow | T004, US-003 T004, US-014 | with T006, T007 |
| [T006](T006-factory-interval.md) | Origin in pocket: 2× interval; do not reset progress | T005 | with T005 |
| [T007](T007-blizzard-hud-overlay.md) | HUD blizzard icons + ground overlay on the pocket | T005 | with T005 |
| [T008](T008-replicate-late-join.md) | Host-authoritative unlock, pocket, slow, factory timers | T005, T006 | |
| [T009](T009-verification-harness.md) | Headless harness + two-window independent test | T005–T008 | |

## Out of scope (stay in other stories)

- Can cozy wielding (US-020).
- Cube recipe (US-019).
- Code Red / fireball (US-018).
- Occupancy rules themselves (US-003 including T011); this story calls the pocket contract.
- Tile drift (US-004).
- Game over when one zone covers the map.

## Independent test (story)

Reach the Baja Blast boss at the dungeon end/exit, defeat it, receive the can / unlock. Cast Bemidji Blizzard onto Reality home: Fantasy pocket for the duration; PP stay and are slowed; factories run slower; buildings cannot place; on expire, speeds and Reality occupancy return.
