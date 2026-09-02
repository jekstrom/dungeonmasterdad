# US-041 tasks: Crib Death

**Story**: [US-041.md](../../US-041.md)  
**Branch**: `041-crib-death`  
**Status**: Todo  
**Tree**: DM (`crib_death`)

Gameplay for **Crib Death** when skill node owned. UI stays US-034. No spend economy in this story.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-ownership-hook.md) | Host ownership flag `crib_death` + harness force-own | Gameplay | US-034 owned chrome if present | |
| [T002](T002-effect.md) | Apply passive effect while owned | Gameplay | T001 | |
| [T003](T003-verification-harness.md) | Owned vs not-owned asserts + multiplayer smoke | QA / Gameplay | T002 | |

## Independent test

Force-own `crib_death`: Automatically summon 1 gremlin from the dungeon exit every minute; each lives 15 seconds. Clear ownership: baseline.
