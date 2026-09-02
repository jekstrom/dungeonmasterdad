# US-050 tasks: Everything Burns

**Story**: [US-050.md](../../US-050.md)  
**Branch**: `050-everything-burns`  
**Status**: Todo  
**Tree**: Dad (`everything_burns`)

Gameplay for **Everything Burns** when skill node owned. UI stays US-035. No spend economy in this story.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-ownership-hook.md) | Host ownership flag `everything_burns` + harness force-own | Gameplay | US-035 owned chrome if present | |
| [T002](T002-effect.md) | Apply passive effect while owned | Gameplay | T001 | |
| [T003](T003-verification-harness.md) | Owned vs not-owned asserts + multiplayer smoke | QA / Gameplay | T002 | |
| [T004](T004-effect-art.md) | Effect VFX | Art | T002 | with Gameplay |

## Independent test

Force-own `everything_burns`: Fireball now destroys resources. Clear ownership: baseline.
