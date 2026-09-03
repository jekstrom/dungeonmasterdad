# US-055 tasks: DM minion spawns near the DM

**Story**: [US-055.md](../../US-055.md)  
**Branch**: `055-dm-minion-near-spawn`  
**Status**: Todo

Shared host placement: **goblin / gremlin / knightling** DM summons land on a random walkable cell near the DM (Chebyshev 1–3 default), not world origin / fixed spots. US-041 exit spawns excluded.

Markdown only until James signs — no Art/Gameplay handoff yet.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-shared-near-dm-picker.md) | Shared host near-DM walkable cell picker (+ inland bias, fail closed) | Gameplay / Systems | DM body + walkability | |
| [T002](T002-wire-gremlin-spawn.md) | Gremlin DM summon uses picker | Gameplay | T001 | with T003 |
| [T003](T003-wire-knightling-spawn.md) | Knightling DM summon uses picker (incl. Chain Lightning multi) | Gameplay | T001 | with T002 |
| [T004](T004-wire-goblin-spawn.md) | Goblin DM summon uses picker (add minimal HUD/ability if missing) | Gameplay | T001 | with T002 |
| [T005](T005-verification-harness.md) | Radius / walkable / inland / fail-closed / multi-knight asserts | QA / Gameplay | T002–T004 | |

## Out of scope

- US-011/012/013 combat AI; US-041 Crib Death exit spawn; dungeon catalog spawns.
