# US-044 tasks: Random Encounter

**Story**: [US-044.md](../../US-044.md)  
**Branch**: `044-random-encounter`  
**Status**: Todo  
**Tree**: DM (`random_encounter`)

Gameplay for **Random Encounter** when skill node owned. UI stays US-034. No spend economy in this story.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-ownership-hook.md) | Host ownership flag `random_encounter` + harness force-own | Gameplay | US-034 owned chrome if present | |
| [T002](T002-effect.md) | Apply passive effect while owned | Gameplay | T001 | |
| [T003](T003-verification-harness.md) | Owned vs not-owned asserts + multiplayer smoke | QA / Gameplay | T002 | |
| [T004](T004-effect-art.md) | Effect VFX | Art | T002 | with Gameplay |

## Independent test

Force-own `random_encounter`: Goblins can now lay traps. Clear ownership: baseline.
