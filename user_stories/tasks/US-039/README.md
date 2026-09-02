# US-039 tasks: Minions

**Story**: [US-039.md](../../US-039.md)  
**Branch**: `039-minions`  
**Status**: Todo  
**Tree**: DM (`minions`)

Gameplay for **Minions** when skill node owned. UI stays US-034. No spend economy in this story.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-ownership-hook.md) | Host ownership flag `minions` + harness force-own | Gameplay | US-034 owned chrome if present | |
| [T002](T002-effect.md) | Apply passive effect while owned | Gameplay | T001 | |
| [T003](T003-verification-harness.md) | Owned vs not-owned asserts + multiplayer smoke | QA / Gameplay | T002 | |

## Independent test

Force-own `minions`: Gremlins can carry 1 more item. Clear ownership: baseline.
