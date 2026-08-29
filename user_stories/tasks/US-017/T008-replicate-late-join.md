# T008: Host-authoritative replicate and late join

**Story**: US-017  
**Status**: Todo  
**Depends on**: T005, T006  
**Parallel**: no

## Goal

Unlock, pocket, PP slow, and factory timers originate on the host. Late joiners receive current unlock, live pocket, current slows, and current factory intervals.

## Files

- `_globals/DMUnlocks.gd` snapshot / `replicate_unlocks`
- US-003 pocket replication (US-003 T009)
- Factory interval state (T006)
- PP move-speed factor (T005)

## Requirements

- FR-009, MR-001, MR-002
- All PP clients in the slow feel the same speed factor.
- Late join: `bemidji_blizzard` unlock bit, live pocket rect + remaining duration, who is slowed, factory remaining scaled time.
- Do not replicate particle RNG (US-026). Do not replicate a PP shove (there is none).

## Acceptance

- **Given** a host unlock, cast, or expire, **When** peers are in session, **Then** they show the same unlock, pocket, slow, and factory timing.
- **Given** a client joins mid-blizzard, **When** they spawn, **Then** they receive current unlock, the live pocket, and matching slows/timers.

## Notes

Boss combat replication is part of T003. This task is the spell/unlock snapshot.
