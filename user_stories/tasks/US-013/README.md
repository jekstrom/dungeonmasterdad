# US-013 tasks: Gremlins relocate resources

**Story**: [US-013.md](../../US-013.md)  
**Branch**: `013-gremlins-relocate`  
**Status**: Signed — ready for Art/Gameplay

James signed at `7d868d8`. Gremlins pick up and drop world resources. **Gremlins ≠ goblins** — dedicated scene, sprites, VFX, HUD/skill icons. No goblin asset reuse.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-gremlin-scene-not-goblin.md) | Dedicated `gremlin.tscn` actor; stop spawning `goblin.tscn` for gremlins | Gameplay | — | with T005 |
| [T002](T002-pickup-carry-drop.md) | Host pickup / carry-1 / timed drop / death drop | Gameplay | T001 | |
| [T003](T003-pathing-and-target-prefer.md) | Path to piles; prefer near factories/IRS | Gameplay | T002 | |
| [T004](T004-replicate-carry-state.md) | Peers agree carried vs dropped; no double-pickup | Gameplay | T002 | |
| [T005](T005-gremlin-art.md) | Gremlin world sheet, HUD icon, optional death FX; no goblin reuse | Art | — | with T001 |
| [T006](T006-verification-harness.md) | Spawn gremlin looks like gremlin; relocate + multiplayer asserts | QA / Gameplay | T002–T005 | |

## Out of scope

- Goblin raids (US-011), knightlings (US-012), skill passives US-039–041.
