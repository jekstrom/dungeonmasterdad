# monsters/gremlin.png layout (US-013 T005)

512×192 RGBA, **64×64 cells**, hframes=8 vframes=3. Transparent bg.
Distinct purple wiry thief — **not** goblin olive / spear / `goblin.png`.

| Row | Cols 0–3 | Cols 4–7 |
|-----|----------|----------|
| 0 | walk South f0–f3 | walk North f0–f3 |
| 1 | walk East f0–f3 | idle S, idle N, idle E, pick South |
| 2 | pick N, pick E, carry idle S/N/E, carry walk S, carry walk E, carry walk N |

West = flip East frames in code.
Carry uses a **generic brown block** offset — do not bake item types.
Death VFX: `monsters/gremlin_poof.png` (256×64, four 64×64 frames).
HUD: `sprites/gremlin_spawn_button.png` (+ `_pressed`).
Skill icons refreshed: `gui/dm/skill_tree/row_gremlins.png`, `icon_minions.png`, `icon_blind_monkeys.png`, `icon_crib_death.png`.
