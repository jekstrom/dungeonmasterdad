# US-038 tasks: Chain Lightning

**Story**: [US-038.md](../../US-038.md)  
**Branch**: `038-chain-lightning`  
**Status**: Todo  
**Tree**: DM (`chain_lightning`)

Gameplay for **Chain Lightning** when skill node owned. UI stays US-034. No spend economy in this story.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-ownership-hook.md) | Host ownership flag `chain_lightning` + harness force-own | Gameplay | US-034 owned chrome if present | |
| [T002](T002-effect.md) | Apply passive effect while owned | Gameplay | T001 | |
| [T003](T003-verification-harness.md) | Owned vs not-owned asserts + multiplayer smoke | QA / Gameplay | T002 | |

## Independent test

Force-own `chain_lightning`: Summon 3 knightlings instead of 1. Clear ownership: baseline.
