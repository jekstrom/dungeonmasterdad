# US-058 tasks: Dungeon goblins hunt the DM, then become a post-exit summon

**Story**: [US-058.md](../../US-058.md)  
**Branch**: `058-dungeon-goblins`  
**Status**: Done  

Goblins spawn in the generated dungeon and aggro the DM during the crawl. First successful dungeon exit unlocks goblin HUD summon. After that, all goblins aggro Paper Pushers and buildings only — never the DM.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-dungeon-goblin-spawns.md) | Place goblins in mids/hallways (not start/exit rooms) | Gameplay | Existing monster planner | |
| [T002](T002-crawl-aggro-dm.md) | Pre-exit goblins aggro and melee the DM | Gameplay | T001 | |
| [T003](T003-exit-unlock-summon.md) | First exit unlocks `goblin`; HUD locked until then | Gameplay | US-015 exit, US-055 HUD | with T002 |
| [T004](T004-post-exit-faction.md) | After exit, all goblins ignore DM; hunt PPs + raid buildings | Gameplay | T002, T003 | |
| [T005](T005-verification-harness.md) | Spawn, crawl aggro, unlock, post-exit faction, late join | QA / Gameplay | T001–T004 | |

## Independent test

Generate: goblins in the dungeon, not start/exit. DM is hunted. Summon locked. Exit: summon unlocks. Summoned and leftover goblins ignore the DM and can raid a factory / chase a PP.
