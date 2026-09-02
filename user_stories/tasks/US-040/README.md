# US-040 tasks: Blind one-legged monkeys

**Story**: [US-040.md](../../US-040.md)  
**Branch**: `040-blind-one-legged-monkeys`  
**Status**: Todo  
**Tree**: DM (`blind_one_legged_monkeys`)

Gameplay for **Blind one-legged monkeys** when skill node owned. UI stays US-034. No spend economy in this story.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-ownership-hook.md) | Host ownership flag `blind_one_legged_monkeys` + harness force-own | Gameplay | US-034 owned chrome if present | |
| [T002](T002-effect.md) | Apply passive effect while owned | Gameplay | T001 | |
| [T003](T003-verification-harness.md) | Owned vs not-owned asserts + multiplayer smoke | QA / Gameplay | T002 | |
| [T004](T004-effect-art.md) | Effect VFX | Art | T002 | with Gameplay |

## Independent test

Force-own `blind_one_legged_monkeys`: Gremlins turn invisible. Clear ownership: baseline.
