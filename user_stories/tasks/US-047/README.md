# US-047 tasks: Put a Sweater On

**Story**: [US-047.md](../../US-047.md)  
**Branch**: `047-put-a-sweater-on`  
**Status**: Todo  
**Tree**: Dad (`put_a_sweater_on`)

Gameplay for **Put a Sweater On** when skill node owned. UI stays US-035. No spend economy in this story.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-ownership-hook.md) | Host ownership flag `put_a_sweater_on` + harness force-own | Gameplay | US-035 owned chrome if present | |
| [T002](T002-effect.md) | Apply passive effect while owned | Gameplay | T001 | |
| [T003](T003-verification-harness.md) | Owned vs not-owned asserts + multiplayer smoke | QA / Gameplay | T002 | |

## Independent test

Force-own `put_a_sweater_on`: Blizzard now does damage. Clear ownership: baseline.
