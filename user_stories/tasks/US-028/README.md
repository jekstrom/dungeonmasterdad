# US-028 tasks: Baja Blast Freeze Wave

**Story**: [US-028.md](../../US-028.md)  
**Branch**: `028-baja-freeze-wave`  
**Status**: Todo

Telegraphed forward Baja wave. Knockback on hit. Wall hit collapses into a configurable icy sheet that makes players slide. Distinct from Carbonated Jet.

## Order

Telegraph (T001), then wave+knockback (T002), then ice sheet (T003). Replication (T004) and harness (T005) close.

| ID | Task | Depends on | Parallel |
|---|---|---|---|
| [T001](T001-wave-telegraph.md) | Readable Freeze Wave telegraph | US-017 T003 | |
| [T002](T002-wave-knockback.md) | Forward wave; host knockback on hit | T001 | |
| [T003](T003-icy-sheet.md) | Wall hit → large icy sheet; reduced friction / slide | T002 | |
| [T004](T004-replicate-wave.md) | Replicate wave, knockback, sheet; duration/size configurable | T003 | |
| [T005](T005-verification-harness.md) | Headless harness + two-window | T003, T004 | |

## Out of scope

- Carbonated Jet (US-027), Sugar Rush (US-029).
- US-019 cube, US-020 cozy, US-018 fireball.
- Bemidji Blizzard pocket (US-017 T005).
- PP occupancy (US-003 T011).

## Independent test (story)

Telegraph, Baja wave, knockback on DM hit, wall collapse to icy slide sheet. Second window matches.
