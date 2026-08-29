# US-002 tasks: Reality Zone tile art drift

**Story**: [US-002.md](../../US-002.md)  
**Branch**: `002-reality-tile-drift`  
**Status**: Todo

Outside grass/dirt in Reality-claimed area stagger-converts to Reality-element presentation of the **same** ground kind. Dungeon cells never restyle. Occupancy stays US-001; this story is art only.

## Order

Do T001 first. Delay (T002) and overlap claim (T004) need eligibility. Apply (T003) needs delay + US-023 strips. Puff (T005) is optional after T003. Replication (T006) and the harness (T007) close the story.

| ID | Task | Depends on | Parallel |
|---|---|---|---|
| [T001](T001-drift-eligibility.md) | Drift eligibility: outside + Reality-claimed, not dungeon | US-001, US-023 | |
| [T002](T002-staggered-delay.md) | Per-tile random delay; convert at most once until claim changes | T001 | with T004 |
| [T003](T003-apply-reality-art.md) | Apply Reality-element of same kind/variety; no collision change | T002, US-023 | |
| [T004](T004-home-overlap-claim.md) | Home overlap with no pocket: higher covering level wins | T001 | with T002 |
| [T005](T005-convert-puff.md) | Optional convert puff (`reality_drift_puff.png`) | T003 | |
| [T006](T006-replicate-late-join.md) | Host-authoritative variants; late join current art | T003 | |
| [T007](T007-verification-harness.md) | Headless harness + two-window independent test | T002–T006 | |

## Out of scope (stay in other stories)

- Occupancy, buildings, skeletons, pocket geometry (US-001).
- Fantasy art drift (US-004), except shared claim / eligibility when a pocket expires.
- Outside catalog membership and dungeon exclusion (US-023).
- Dungeon interior restyle (paper vs sparkle dungeon stone).

## Independent test (story)

Cover a mix of outside grass/dirt cells and dungeon floor cells with the Reality home rectangle. Outside cells stagger-convert to Reality-element grass/dirt; dungeon cells keep dungeon catalog art. Spawn a Reality pocket over Fantasy-looking grass: those cells become eligible for Reality drift for the pocket duration; when it expires they become eligible for Fantasy drift again if Fantasy still claims them.
