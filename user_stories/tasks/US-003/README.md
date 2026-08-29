# US-003 tasks: Fantasy Zone play space

**Story**: [US-003.md](../../US-003.md)  
**Branch**: `003-fantasy-zone`  
**Status**: Todo

The Dungeon Master holds an east-anchored rectangular Fantasy home that grows with Fantasy Level, plus temporary rectangular pockets (Bemidji Blizzard will call the pocket contract). Paper Pushers **walk** Fantasy-claimed ground (T005 revoked; T011). Buildings that touch it are rejected. Skeletons may exist there unless Reality-claimed under US-001.

## Order

Do T001 first. Home (T002) and overlays (T003) need the claim API. Pockets (T004) need claim + clip. Occupancy, buildings, and skeletons (T006–T008, T011) need claim. Replication (T009) and the harness (T010) close the story. Skip T005.

| ID | Task | Depends on | Parallel |
|---|---|---|---|
| [T001](T001-fantasy-claim-api.md) | Fantasy claim API (home ∪ pockets, not a circle) | — | |
| [T002](T002-home-rectangle.md) | East-anchored home, grows with Fantasy Level, clip | T001, US-024 T013 | with T003 |
| [T003](T003-claimed-overlays.md) | Player-facing overlays on claimed cells | T001 | with T002 |
| [T004](T004-pocket-contract.md) | Pocket contract: origin/size/duration, clip, newer wins, expire | T001 | |
| [T005](T005-paper-pusher-exclusion.md) | **Revoked** — PP exclusion/push-out | — | |
| [T006](T006-dm-occupancy.md) | DM paths freely in Fantasy-claimed | T001 | with T011 |
| [T007](T007-building-reject.md) | Reject buildings whose footprint intersects Fantasy | T001 | |
| [T008](T008-skeleton-allow.md) | Skeletons allowed unless Reality-claimed (US-001) | T001, US-001 | |
| [T009](T009-replicate-late-join.md) | Replicate home, pockets (no PP displacement) | T002, T004 | |
| [T010](T010-verification-harness.md) | Headless harness + two-window independent test | T006–T009, T011 | |
| [T011](T011-paper-pusher-walk.md) | Paper Pushers walk Fantasy; no wall, no push-out | T001 | with T006 |

## Out of scope (stay in other stories)

- Fantasy art drift on outside grass/dirt (US-004).
- Reality home and Reality pockets (US-001) except the Reality-claim query T008 needs. Home exclusivity is US-025.
- Blizzard slow amounts and unlock (US-017); T004 is the pocket contract blizzard will call.
- Named pocket abilities besides that contract.
- Map cliff geometry and overworld fill (US-024), except using T013 clip.
- Game over when one zone covers the map.

## Independent test (story)

Grow a rectangular Fantasy home. A Paper Pusher walks in and out; they are not stopped and not pushed. The DM walks through it. A building placement whose footprint touches it is rejected. A skeleton can exist inside it (if not Reality-claimed). Cast a Fantasy pocket over Reality home: Paper Pushers in that rectangle stay; new buildings there are rejected; skeletons may exist there; when the pocket expires, Reality home rules return. A late joiner sees the same home, pockets, and occupancy.
