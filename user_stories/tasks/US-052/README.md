# US-052 tasks: Dad Reflexes

**Story**: [US-052.md](../../US-052.md)  
**Branch**: `052-dad-reflexes`  
**Status**: Todo  
**Tree**: Dad (`dad_reflexes`)

Gameplay for **Dad Reflexes** when skill node owned. UI stays US-035. No spend economy in this story.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-ownership-hook.md) | Host ownership flag `dad_reflexes` + harness force-own | Gameplay | US-035 owned chrome if present | |
| [T002](T002-effect.md) | Apply passive effect while owned | Gameplay | T001 | |
| [T003](T003-verification-harness.md) | Owned vs not-owned asserts + multiplayer smoke | QA / Gameplay | T002 | |
| [T004](T004-effect-art.md) | Effect VFX | Art | T002 | with Gameplay |

## Independent test

Force-own `dad_reflexes`: Gain dash ability. Clear ownership: baseline.
