# US-042 tasks: Challenge Rating

**Story**: [US-042.md](../../US-042.md)  
**Branch**: `042-challenge-rating`  
**Status**: Todo  
**Tree**: DM (`challenge_rating`)

Gameplay for **Challenge Rating** when skill node owned. UI stays US-034. No spend economy in this story.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-ownership-hook.md) | Host ownership flag `challenge_rating` + harness force-own | Gameplay | US-034 owned chrome if present | |
| [T002](T002-effect.md) | Apply passive effect while owned | Gameplay | T001 | |
| [T003](T003-verification-harness.md) | Owned vs not-owned asserts + multiplayer smoke | QA / Gameplay | T002 | |

## Independent test

Force-own `challenge_rating`: Increase goblin HP. Clear ownership: baseline.
