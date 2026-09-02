# US-051 tasks: Thermostat Lock

**Story**: [US-051.md](../../US-051.md)  
**Branch**: `051-thermostat-lock`  
**Status**: Todo  
**Tree**: Dad (`thermostat_lock`)

Gameplay for **Thermostat Lock** when skill node owned. UI stays US-035. No spend economy in this story.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-ownership-hook.md) | Host ownership flag `thermostat_lock` + harness force-own | Gameplay | US-035 owned chrome if present | |
| [T002](T002-effect.md) | Apply passive effect while owned | Gameplay | T001 | |
| [T003](T003-verification-harness.md) | Owned vs not-owned asserts + multiplayer smoke | QA / Gameplay | T002 | |

## Independent test

Force-own `thermostat_lock`: Paper Pushers lose one inventory slot. Clear ownership: baseline.
