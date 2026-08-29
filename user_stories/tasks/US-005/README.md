# US-005 tasks: Paper Pusher combat loadout

**Story**: [US-005.md](../../US-005.md)  
**Branch**: `005-paper-pusher-combat`  
**Status**: Todo

Each Paper Pusher fights with a staple-gun magazine (ranged) and a huge pencil melee. Restock is US-010. Chainsaw is US-022.

## Order

Do T001 first (magazine + HUD). Fire (T002–T004) needs ammo. Melee (T005) can run in parallel with fire. Same-frame priority (T006) needs both. Lockouts (T007) and the gun sheet (T008) can run beside combat. Replication (T009) and the harness (T010) close the story.

| ID | Task | Depends on | Parallel |
|---|---|---|---|
| [T001](T001-staple-magazine-hud.md) | Per-PP magazine (default 20) + HUD icon, replicate to owner | — | |
| [T002](T002-staple-primary-fire.md) | Host-validated staple projectile, consume 1, die on hit/wall/range | T001 | with T005 |
| [T003](T003-empty-magazine-feedback.md) | Empty magazine: no projectile, empty-click/jam | T002 | |
| [T004](T004-host-hit-damage.md) | Host hit once; buildings take no staple damage; zones do not cancel | T002 | |
| [T005](T005-pencil-melee.md) | Huge pencil swing + hurtbox, current melee_damage, no staple spend | — | with T002 |
| [T006](T006-same-frame-melee-wins.md) | Same-frame melee vs fire: melee wins, do not spend a staple | T002, T005 | |
| [T007](T007-noncombat-lockouts.md) | Dead / building / existing attack-block states block both | T002, T005 | |
| [T008](T008-staple-gun-sheet.md) | Wire `player_staple_gun.png` for ranged; do not stretch the sword | T002 | with T005 |
| [T009](T009-replicate-combat.md) | Replicate projectile spawn, swing, damage; client cannot over-fire | T002, T005 | |
| [T010](T010-verification-harness.md) | Headless harness + two-window independent test | T003–T009 | |

## Out of scope (stay in other stories)

- Office Max restock (US-010).
- Pull-start chainsaw (US-022).
- Harvest tools (US-006, US-007).
- Goblin building damage (US-011); staples do not damage buildings here.

## Independent test (story)

Control a Paper Pusher with staples in magazine: fire the staple gun at a dummy and see projectile damage. Empty the magazine and confirm it cannot fire. Switch to or stand in melee range with the pen/pencil and confirm a melee hit. Both attacks replicate to a second peer.
