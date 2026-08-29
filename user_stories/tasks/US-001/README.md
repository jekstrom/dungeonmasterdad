# US-001 tasks: Reality Zone play space

**Story**: [US-001.md](../../US-001.md)  
**Branch**: `001-reality-zone`  
**Status**: Todo

Paper Pushers hold a west-anchored rectangular Reality home that grows with Reality Level, plus temporary rectangular pockets. Occupancy, buildings, and the skeleton ban use the **claim** (home ∪ live pockets), never a circle.

## Order

Do T001 first. Home (T002) and overlays (T003) need the claim API. Pockets (T004) need claim + clip. Occupancy, buildings, and the skeleton ban (T005–T007) need claim. Replication (T008) and the harness (T009) close the story.

| ID | Task | Depends on | Parallel |
|---|---|---|---|
| [T001](T001-reality-claim-api.md) | Reality claim API (home ∪ pockets, not a circle) | — | |
| [T002](T002-home-rectangle.md) | West-anchored home, grows with Reality Level, clip | T001, US-024 T013 | with T003 |
| [T003](T003-claimed-overlays.md) | Player-facing overlays on claimed cells | T001 | with T002 |
| [T004](T004-pocket-contract.md) | Pocket contract: origin/size/duration, clip, newer wins, expire | T001 | |
| [T005](T005-reality-occupancy.md) | Paper Pushers and DM path in Reality-claimed | T001 | with T006 |
| [T006](T006-building-placement.md) | Buildings: whole footprint in Reality, outside tiles, not dungeon | T001 | with T005 |
| [T007](T007-skeleton-ban.md) | Skeleton ban: walk-in, spawn, coverage growth | T001 | |
| [T008](T008-replicate-late-join.md) | Replicate home, pockets, skeleton removals | T002, T004, T007 | |
| [T009](T009-verification-harness.md) | Headless harness + two-window independent test | T005–T008 | |

## Out of scope (stay in other stories)

- Tile art swapping on outside grass/dirt (US-002).
- Fantasy home, Fantasy pockets, and Paper Pusher walk in Fantasy (US-003 T011).
- How Reality Level is earned (US-008, US-009).
- Named Paper Pusher pocket abilities (only the region contract in T004).
- Map cliff geometry and overworld fill (US-024), except using T013 clip.

## Independent test (story)

Stand in a rectangular Reality home: Paper Pushers walk it; the DM can walk in; a legal building places; a skeleton that enters is removed. Grow the rectangle with Reality Level and confirm newly covered skeletons die. Spawn a temporary Reality pocket over Fantasy-covered ground: Paper Pushers may occupy that pocket, buildings may place if fully inside it, skeletons in it die. When the pocket expires, remaining claim is re-evaluated. A late joiner sees the same home, pockets, and living skeletons.
