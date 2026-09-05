# T005: Verification harness

**Story**: US-058  
**Status**: Todo  
**Depends on**: T001–T004  
**Owner**: QA / Gameplay

## Goal

Headless Node + `.tscn` under `test_harness/procedural_dungeon/`:

1. Generate: goblin count in range; none in start/exit rooms; skeletons/boss still present when enabled.
2. Pre-exit: goblin `aggro_faction` hunts DM; summon `try_cast` fails (no mana spend).
3. Simulate first exit: unlock `goblin` is owned; summon would succeed with mana.
4. Post-exit: goblin faction is PLAYERS (or equivalent); DM is not in `_character_aggro_candidates`.
5. Playground `generate_on_ready` stays false; clients do not generate extra goblins.

## Requirements

- AC1–AC8, MR-001–MR-003

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** owned asserts pass without the editor.
