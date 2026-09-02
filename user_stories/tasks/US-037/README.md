# US-037 tasks: Spark

**Story**: [US-037.md](../../US-037.md)  
**Branch**: `037-spark`  
**Status**: Todo  
**Tree**: DM (`spark`)

Gameplay for **Spark** when skill node owned. UI stays US-034. No spend economy in this story.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-ownership-hook.md) | Host ownership flag `spark` + harness force-own | Gameplay | US-034 owned chrome if present | |
| [T002](T002-effect.md) | Apply passive effect while owned | Gameplay | T001 | |
| [T003](T003-verification-harness.md) | Owned vs not-owned asserts + multiplayer smoke | QA / Gameplay | T002 | |

## Independent test

Force-own `spark`: Reduces time between knightling attacks. Clear ownership: baseline.
