# US-036 tasks: Overcharged

**Story**: [US-036.md](../../US-036.md)  
**Branch**: `036-overcharged`  
**Status**: Todo  
**Tree**: DM (`overcharged`)

Gameplay for **Overcharged** when skill node owned. UI stays US-034. No spend economy in this story.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-ownership-hook.md) | Host ownership flag `overcharged` + harness force-own | Gameplay | US-034 owned chrome if present | |
| [T002](T002-effect.md) | Apply passive effect while owned | Gameplay | T001 | |
| [T003](T003-verification-harness.md) | Owned vs not-owned asserts + multiplayer smoke | QA / Gameplay | T002 | |

## Independent test

Force-own `overcharged`: Increase distance traveled by knightlings. Clear ownership: baseline.
