# US-028 tasks: Baja Blast fountain slick

**Story**: [US-028.md](../../US-028.md)  
**Branch**: `028-baja-fountain-slick`  
**Status**: Todo

Water fountain doodad in the Baja Blast boss room. Periodically charges, then splashes Baja Mt Dew around that room: knockback on overlap, then a configurable dew slick that makes the floor slippery. Same Freeze Wave *feel*, environmental source. Not a boss move. Not Carbonated Jet.

## Order

Fountain placement (T001) first. Periodic splash + knockback (T002) needs the doodad. Dew slick (T003) needs the splash. Replication (T004) and harness (T005) close.

| ID | Task | Depends on | Parallel |
|---|---|---|---|
| [T001](T001-fountain-doodad.md) | One water fountain in the dungeon; skip-fountain flag | dungeon gen | |
| [T002](T002-periodic-splash.md) | Charge then room splash; host hit + knockback | T001 | |
| [T003](T003-dew-slick.md) | Splash → dew slick; reduced friction / slide | T002 | |
| [T004](T004-replicate-fountain.md) | Replicate splash, knockback, slick; duration/size configurable | T003 | |
| [T005](T005-verification-harness.md) | Headless harness + two-window | T003, T004 | |

## Out of scope

- Carbonated Jet (US-027), Sugar Rush (US-029) boss moves.
- Freeze Wave / wave state on `baja_boss`.
- US-019 cube, US-020 cozy, US-018 fireball.
- Bemidji Blizzard pocket (US-017 T005).
- PP occupancy (US-003 T011).
- Pickup Baja can (`pickups/bajablast/`).

## Independent test (story)

Fountain in a dungeon room. Charge, Baja splash around the room, knockback on overlap, slick floor that slides then expires. Fountain is not a boss clip. Second window matches.
