# US-045 tasks: Bemidji Cold

**Story**: [US-045.md](../../US-045.md)  
**Branch**: `045-bemidji-cold`  
**Status**: Todo  
**Tree**: Dad (`bemidji_cold`)

Gameplay for **Bemidji Cold** when skill node owned. UI stays US-035. No spend economy in this story.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-ownership-hook.md) | Host ownership flag `bemidji_cold` + harness force-own | Gameplay | US-035 owned chrome if present | |
| [T002](T002-effect.md) | Apply passive effect while owned | Gameplay | T001 | |
| [T003](T003-verification-harness.md) | Owned vs not-owned asserts + multiplayer smoke | QA / Gameplay | T002 | |

## Independent test

Force-own `bemidji_cold`: Increase duration of blizzard. Clear ownership: baseline.
