# US-025 tasks: Zone homes do not overlap

**Story**: [US-025.md](../../US-025.md)  
**Branch**: `025-zone-home-no-overlap`  
**Status**: Todo

Reality and Fantasy homes never share cells. Higher zone value pushes the weaker home rect back. Equal value is a stable frontier. Pockets still override. Drift art must match current claim (no linger).

This supersedes US-001 FR-010 / US-003 FR-010 (homes may overlap) and US-002 FR-007 / US-004 T004 (overlapping homes, ties keep current art).

## Order

Do T001 first. Pushback (T002) and equal frontier (T003) implement the resolve. Pockets (T004) need exclusive homes underneath. Presentation (T005) needs the live claim. Replication (T006) and the harness (T007) close the story.

| ID | Task | Depends on | Parallel |
|---|---|---|---|
| [T001](T001-no-overlap-homes.md) | Homes never occupy the same cells | US-001 T002, US-003 T002 | |
| [T002](T002-pushback-shrink.md) | Higher zone value wins contested cells; weaker rect shrinks | T001 | with T003 |
| [T003](T003-equal-value-frontier.md) | Equal value: neither advances; confirm old stories | T001 | with T002 |
| [T004](T004-pockets-override.md) | Pockets still override; expire returns to no-overlap homes | T001, US-001 T004, US-003 T004 | |
| [T005](T005-drift-follows-claim.md) | No Fantasy art outside Fantasy claim; no Reality art outside Reality claim | T001, US-002, US-004 | |
| [T006](T006-replicate-late-join.md) | Host-authoritative shrunk homes; late join current rects + art | T002, T005 | |
| [T007](T007-verification-harness.md) | Headless harness + two-window independent test | T002–T006 | |

## Out of scope (stay in other stories)

- Game over when one zone covers the map.
- Occupancy movement / buildings / skeletons (US-001, US-003), except home exclusivity.
- Catalog membership (US-023).
- Pocket geometry and blizzard slow (US-017).
- How Reality / Fantasy Level is earned (US-008, US-009).

## Independent test (story)

Grow Reality and Fantasy homes until they would meet. They abut; they do not share cells. Raise one zone’s level: that home takes the contested cells and the weaker home rect shrinks off them. Equal levels: neither home advances into the other. Cast a pocket over the other home: occupancy and drift follow the pocket; when it expires, homes are still the no-overlap rects. A cell that loses Fantasy claim must not keep Fantasy grass/dirt art.
