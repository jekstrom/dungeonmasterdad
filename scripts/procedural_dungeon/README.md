# Procedural Dungeon Module

This directory contains procedural dungeon generation logic for feature branch `001-procedural-dungeon-generator`.

## Ownership Notes

- **Authoritative orchestration** belongs in `_globals/dungeon_generation_manager.gd`.
- **Generation primitives** (graph/maze/carving/validation) belong under `scripts/procedural_dungeon/`.
- **Data resources** used by the generation manager belong under `scripts/procedural_dungeon/resources/`.
- **Runtime scene swap** uses `scenes/generated_dungeon_container.tscn` to avoid partial commits.

## Constraints

- Server-authoritative generation only.
- Reuse existing tile scenes under `level/` and existing monster scenes under `monsters/`.
- Keep all new scripts typed and snake_case-named.
