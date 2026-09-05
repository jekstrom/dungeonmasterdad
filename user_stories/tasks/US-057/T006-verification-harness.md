# T006: Verification harness

**Story**: US-057  
**Status**: Todo  
**Depends on**: T003, T004, T005  
**Owner**: QA / Gameplay

## Goal

Headless contract tests (Node + `.tscn`, `test_harness/procedural_dungeon/`):

1. Square bounds, N seeds: walkable AABB aspect ≤ 1.8 (or documented cap).
2. Shortest path length ≥ 1.4× Chebyshev(start, exit) on typical seeds.
3. Start/exit not required on opposite edges; an interior pair succeeds.
4. PathValidator still connects; one entrance, one exit.
5. Layout has hallway cells that are not a pure L-set from room centers.
6. Start-room Dew / Code Red planners still accept the new room_regions.
7. `generate_on_ready` stays false on playground; clients do not generate.

## Requirements

- AC1–AC9, FR-010, MR-001

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** owned metrics pass without the editor.
- **Given** old L-backbone-only asserts, **When** they conflict, **Then** they are updated in this story — not kept as a reason to retain sausage layouts.
