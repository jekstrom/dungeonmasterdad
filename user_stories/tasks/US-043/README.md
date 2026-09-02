# US-043 tasks: +1 Swords

**Story**: [US-043.md](../../US-043.md)  
**Branch**: `043-plus-one-swords`  
**Status**: Todo  
**Tree**: DM (`plus_one_swords`)

Gameplay for **+1 Swords** when skill node owned. UI stays US-034. No spend economy in this story.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-ownership-hook.md) | Host ownership flag `plus_one_swords` + harness force-own | Gameplay | US-034 owned chrome if present | |
| [T002](T002-effect.md) | Apply passive effect while owned | Gameplay | T001 | |
| [T003](T003-verification-harness.md) | Owned vs not-owned asserts + multiplayer smoke | QA / Gameplay | T002 | |

## Independent test

Force-own `plus_one_swords`: Increase goblin attack damage. Clear ownership: baseline.
