# Procedural Dungeon Module

This directory contains procedural dungeon generation logic for feature branch `001-procedural-dungeon-generator`.

## Ownership Notes

- **Authoritative orchestration** belongs in `_globals/dungeon_generation_manager.gd` (RPC, queries, fountain runtime).
- **Generation pipeline** is a state machine under `scripts/procedural_dungeon/generation/` (`DungeonGenerationStateMachine`).
- **Generation primitives** (graph/maze/carving/validation) belong under `scripts/procedural_dungeon/`.
- **Data resources** used by the generation manager belong under `scripts/procedural_dungeon/resources/`.
- **Runtime scene swap** uses `scenes/generated_dungeon_container.tscn` to avoid partial commits.

Pipeline states: Idle → ValidateRequest → GenerateLayout → PopulateSpawns → ValidateLayout → CommitWorld → Succeeded | Rejected. Layout retries return to GenerateLayout. `generate_dungeon_contract` still runs the machine to completion in one call.

Lifecycle signals on `SignalBus`: `dungeon_generation_requested`, `dungeon_generation_state_changed`, `dungeon_generation_succeeded`, `dungeon_generation_failed`.

## Constraints

- Server-authoritative generation only.
- Reuse existing tile scenes under `level/` and existing monster scenes under `monsters/`.
- Keep all new scripts typed and snake_case-named.
