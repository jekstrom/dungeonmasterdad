# US-004 tasks: Fantasy Zone tile art drift

**Story**: [US-004.md](../../US-004.md)  
**Branch**: `004-fantasy-tile-drift`  
**Status**: Todo

Outside grass/dirt in Fantasy-claimed area stagger-converts to Fantasy-element presentation of the **same** ground kind. Dungeon cells never restyle. Occupancy stays US-003; this story is art only. Shares the US-002 claim winner so Reality and Fantasy drift cannot fight.

## Order

Do T001 first. Delay (T002) and shared claim (T004) need eligibility. Apply (T003) needs delay + US-023 strips. Puff (T005) is after T003 and must not block it. Replication (T006) and the harness (T007) close the story.

| ID | Task | Depends on | Parallel |
|---|---|---|---|
| [T001](T001-drift-eligibility.md) | Drift eligibility: outside + Fantasy-claimed, not dungeon, not Reality-claimed | US-003, US-002 T004, US-023 | |
| [T002](T002-staggered-delay.md) | Per-tile random delay; convert at most once until claim changes | T001 | with T004 |
| [T003](T003-apply-fantasy-art.md) | Apply Fantasy-element of same kind/variety; no collision change | T002, US-023 | |
| [T004](T004-shared-claim.md) | Shared claim: pockets override homes; higher covering level wins | T001 | with T002 |
| [T005](T005-convert-puff.md) | Convert puff (`fantasy_drift_puff.png`) | T003 | |
| [T006](T006-replicate-late-join.md) | Host-authoritative variants; late join current art | T003 | |
| [T007](T007-verification-harness.md) | Headless harness + two-window independent test | T002–T006 | |

## Perf

Schedule drift on claim/map change only. Do **not** scan every outside tile every physics frame. Same constraint as US-002.

## Out of scope (stay in other stories)

- Occupancy, buildings, skeletons, pocket geometry (US-003).
- Reality art content (US-002), except the shared claim / eligibility when a Fantasy pocket expires.
- Outside catalog membership and dungeon exclusion (US-023).
- Dungeon interior restyle (paper vs sparkle dungeon stone).
- Blizzard slow (US-017); this story only restyles tiles in the Fantasy claim.

## Independent test (story)

Cover a mix of outside grass/dirt cells and dungeon floor cells with the Fantasy home rectangle. Outside cells stagger-convert to Fantasy-element grass/dirt; dungeon cells keep dungeon catalog art. Cast a Fantasy pocket over Reality-looking grass: those cells become eligible for Fantasy drift for the pocket duration; when it expires they become eligible for Reality drift again if Reality still claims them.
