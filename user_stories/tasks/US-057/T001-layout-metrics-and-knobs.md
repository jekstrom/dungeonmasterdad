# T001: Layout metrics and knobs

**Story**: US-057  
**Status**: Todo  
**Depends on**: existing `DungeonGenerationRequest`  
**Owner**: Gameplay

## Goal

Make “not a long sausage” and “mazelike” measurable, and expose knobs without inventing a second generator API.

Suggested:

- Walkable AABB aspect = max(w, h) / max(1, min(w, h)); default fail/retry if **> 1.8** when bounds themselves are square (aspect ≤ 1.2).
- Winding: shortest PathValidator length ≥ **1.4×** Chebyshev(start, exit) (or room centers).
- Optional request/inspector: `braid_rate` (0–1), `auto_place_portals` or sentinel cells.
- Keep `room_size`, `room_count`, `generation_bounds`, explicit start/exit when valid.

## Files

- `scripts/procedural_dungeon/resources/dungeon_generation_request.gd`
- `scripts/procedural_dungeon/dungeon_generator.gd` (inspector)
- `scripts/procedural_dungeon/generation/dungeon_layout_builder.gd` (retry hooks)
- Suggested helper: layout metrics next to `path_validator.gd`

## Requirements

- FR-006, FR-008, FR-009, AC1, AC4

## Acceptance

- **Given** a composed layout, **When** metrics run, **Then** aspect and path-length ratios are available to the builder for retry.
- **Given** square bounds and a sausage layout, **When** aspect exceeds the default, **Then** the attempt is rejected and another seed/attempt may run (existing attempt cap).
