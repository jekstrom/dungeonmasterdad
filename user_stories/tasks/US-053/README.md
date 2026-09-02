# US-053 tasks: Grounded

**Story**: [US-053.md](../../US-053.md)  
**Branch**: `053-grounded`  
**Status**: Todo  
**Tree**: Dad (`grounded`)

Gameplay for **Grounded** when skill node owned. UI stays US-035. No spend economy in this story.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-ownership-hook.md) | Host ownership flag `grounded` + harness force-own | Gameplay | US-035 owned chrome if present | |
| [T002](T002-effect.md) | Apply passive effect while owned | Gameplay | T001 | |
| [T003](T003-verification-harness.md) | Owned vs not-owned asserts + multiplayer smoke | QA / Gameplay | T002 | |

## Independent test

Force-own `grounded`: Paper Pushers can only survive in Fantasy for 3 seconds. Clear ownership: baseline.
