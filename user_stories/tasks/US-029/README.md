# US-029 tasks: Baja Blast Sugar Rush

**Story**: [US-029.md](../../US-029.md)  
**Branch**: `029-baja-sugar-rush`  
**Status**: Todo

Once at 50% HP: 10s overcaffeinated frenzy. Move/attack speed up, damage taken +15%, vibrate + bubbles. Timed buff, not a forever phase.

## Order

Trigger (T001) first. Buff numbers (T002) and VFX (T003) can overlap. Replication (T004) and harness (T005) close.

| ID | Task | Depends on | Parallel |
|---|---|---|---|
| [T001](T001-once-at-half.md) | Trigger once at 50% HP | US-017 T003 | |
| [T002](T002-timed-buff.md) | 10s: move/attack speed up, +15% damage taken | T001 | with T003 |
| [T003](T003-vibrate-bubbles.md) | Vibrate + bubble particles while active | T001 | with T002 |
| [T004](T004-replicate-rush.md) | Host-authoritative buff; late join sees it | T002 | |
| [T005](T005-verification-harness.md) | Headless harness + two-window | T002–T004 | |

## Out of scope

- Carbonated Jet (US-027) move body. Fountain slick (US-028) doodad.
- US-019 cube, US-020 cozy, US-018 fireball.
- PP occupancy (US-003 T011).

## Independent test (story)

Drop the boss to 50% HP once: 10s frenzy, then baseline. Does not stay in a second phase. Second window matches the buff window.
