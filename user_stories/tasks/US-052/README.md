# US-052 tasks: Dad Reflexes

**Story**: [US-052.md](../../US-052.md)  
**Branch**: `052-dad-reflexes`  
**Status**: Todo  
**Tree**: Dad (`dad_reflexes`)

Gameplay for **Dad Reflexes** when skill node owned: **1.5× DM movement speed** (not a dash). UI stays US-035 except this node’s effect text. No spend economy in this story.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-ownership-hook.md) | Host ownership flag `dad_reflexes` + harness force-own | Gameplay | US-035 owned chrome if present | |
| [T002](T002-effect.md) | Apply 1.5× DM move speed while owned | Gameplay | T001 | |
| [T003](T003-verification-harness.md) | Owned vs not-owned speed asserts + multiplayer smoke | QA / Gameplay | T002 | |
| [T004](T004-effect-art.md) | No dedicated VFX | Art | T002 | with Gameplay |

## Independent test

Force-own `dad_reflexes`: DM moves at **1.5×** baseline; no dash. Clear ownership: baseline speed.
