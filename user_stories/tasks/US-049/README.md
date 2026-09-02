# US-049 tasks: Full Cord

**Story**: [US-049.md](../../US-049.md)  
**Branch**: `049-full-cord`  
**Status**: Todo  
**Tree**: Dad (`full_cord`)

Gameplay for **Full Cord** when skill node owned. UI stays US-035. No spend economy in this story.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-ownership-hook.md) | Host ownership flag `full_cord` + harness force-own | Gameplay | US-035 owned chrome if present | |
| [T002](T002-effect.md) | Apply passive effect while owned | Gameplay | T001 | |
| [T003](T003-verification-harness.md) | Owned vs not-owned asserts + multiplayer smoke | QA / Gameplay | T002 | |

## Independent test

Force-own `full_cord`: Reduce cooldown and mana cost of fireball. Clear ownership: baseline.
