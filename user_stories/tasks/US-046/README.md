# US-046 tasks: T-Shirt in December

**Story**: [US-046.md](../../US-046.md)  
**Branch**: `046-tshirt-in-december`  
**Status**: Todo  
**Tree**: Dad (`tshirt_in_december`)

Gameplay for **T-Shirt in December** when skill node owned. UI stays US-035. No spend economy in this story.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-ownership-hook.md) | Host ownership flag `tshirt_in_december` + harness force-own | Gameplay | US-035 owned chrome if present | |
| [T002](T002-effect.md) | Apply passive effect while owned | Gameplay | T001 | |
| [T003](T003-verification-harness.md) | Owned vs not-owned asserts + multiplayer smoke | QA / Gameplay | T002 | |
| [T004](T004-effect-art.md) | Effect VFX | Art | T002 | with Gameplay |

## Independent test

Force-own `tshirt_in_december`: Add a frost trail behind you (the DM). Clear ownership: baseline.
