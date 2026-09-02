# US-048 tasks: Stoke

**Story**: [US-048.md](../../US-048.md)  
**Branch**: `048-stoke`  
**Status**: Todo  
**Tree**: Dad (`stoke`)

Gameplay for **Stoke** when skill node owned. UI stays US-035. No spend economy in this story.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-ownership-hook.md) | Host ownership flag `stoke` + harness force-own | Gameplay | US-035 owned chrome if present | |
| [T002](T002-effect.md) | Apply passive effect while owned | Gameplay | T001 | |
| [T003](T003-verification-harness.md) | Owned vs not-owned asserts + multiplayer smoke | QA / Gameplay | T002 | |

## Independent test

Force-own `stoke`: Increase fireball radius. Clear ownership: baseline.
