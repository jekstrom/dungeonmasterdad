# US-013 tasks: Gremlins relocate resources

**Story**: [US-013.md](../../US-013.md)  
**Branch**: `013-gremlins-relocate`  
**Status**: Signed — ready for Art/Gameplay

James signed at `7d868d8`. **Behavior add (still Signed):** 2× move speed, walkable-only pathing, staples damage, always flee PPs. Gremlins pick up and drop world resources. **Gremlins ≠ goblins** — dedicated scene, sprites, VFX, HUD/skill icons. No goblin asset reuse.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-gremlin-scene-not-goblin.md) | Dedicated `gremlin.tscn` actor; stop spawning `goblin.tscn` for gremlins | Gameplay | — | with T005 |
| [T002](T002-pickup-carry-drop.md) | Host pickup / carry-1 / timed drop / death drop | Gameplay | T001 | |
| [T003](T003-pathing-and-target-prefer.md) | Walkable-only pathing; prefer factories/IRS; always flee PPs | Gameplay | T002 | |
| [T004](T004-replicate-carry-state.md) | Peers agree carried vs dropped; no double-pickup | Gameplay | T002 | |
| [T005](T005-gremlin-art.md) | Gremlin world sheet, HUD icon, optional death FX; no goblin reuse | Art | — | with T001 |
| [T006](T006-verification-harness.md) | Spawn≠goblin; relocate; speed; walkable; staples; flee; multiplayer | QA / Gameplay | T002–T005, T007–T008 | |
| [T007](T007-move-speed-2x.md) | Move speed = 2× pre-fix baseline | Gameplay | T001 | with T002 |
| [T008](T008-staples-damage-hurtbox.md) | Staples hit hurtbox; damage/kill; drop on death | Gameplay | T001; US-005 staples | with T002 |

## Out of scope

- Goblin raids (US-011), knightlings (US-012), skill passives US-039–041.
- Gremlins damaging Paper Pushers.
