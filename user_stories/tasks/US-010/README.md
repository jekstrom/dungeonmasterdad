# US-010 tasks: Restock staples at Office Max

**Story**: [US-010.md](../../US-010.md)  
**Branch**: `010-office-max`  
**Status**: Todo — **James has not signed the revised story. Do not implement or hand off to Art / Gameplay / QA until he does.**

Office Max is the only full staple restock for US-005 magazines. Unique buildable (max one), iron to place, Reality placement. Interact fills the interacting player's magazine to max for **1 iron per 10 staples refilled**. Building has HP (suggested 16) and a **ruined** destroyed art.

## Order

Art (T001) can run first or in parallel with the buildable shell (T002). Restock (T003) needs T002 + US-005 magazine. Gates (T004) and destroy/ruin (T005) need restock. Replication (T006) and harness (T007) close.

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-office-max-art.md) | Wire Office Max building, **ruined**, + build icons | Art | — | with T002 |
| [T002](T002-unique-buildable.md) | Unique buildable, iron place cost, HP, US-001/US-003 placement | Gameplay | US-001 T006, US-007 | with T001 |
| [T003](T003-restock-interact.md) | Interact refill to max; **1 iron / 10 staples** (`ceil`) | Gameplay | T002, US-005 T001 | |
| [T004](T004-restock-gates.md) | Out of range / full / ghost / **not enough iron**: reject | Gameplay | T003 | |
| [T005](T005-destroyed-unavailable.md) | 0 HP → ruined art; restock off until rebuilt | Gameplay | T001, T003 | |
| [T006](T006-replicate-uniqueness.md) | Host uniqueness, HP, iron+mag restock; two PPs independent | Gameplay | T003 | |
| [T007](T007-verification-harness.md) | Headless harness + two-window independent test | QA | T003–T006 | |

## Out of scope (stay in other stories)

- Staple gun firing (US-005).
- IRS (US-009).
- Goblin raid AI (US-011); HP + ruin + restock gate only here.
- DM mana (US-014).
- US-027 trail rework, US-028 Freeze Wave, US-029 Sugar Rush.
- US-019 cube, US-020 cozy, US-018 fireball.

## Independent test (story)

Empty the magazine with enough iron, restock at Office Max: mag full, iron spent at 1 per 10 staples. Not enough iron: reject. Away from building: fail. Second placement rejected. Destroy: ruined art, no restock until rebuild.
