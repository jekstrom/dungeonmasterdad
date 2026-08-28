# T015: Verification harness and independent test

**Story**: US-024  
**Status**: Done  
**Depends on**: T007–T014  
**Parallel**: no

## Goal

Prove the independent test in automation where possible, and list the play pass that still needs a host+client session.

## Files

- `test_harness/procedural_dungeon/us024_map_bounds_test.gd` (+ `.tscn`) — Node script that quits on success (testing skill)
- Optional: extend `test_harness/procedural_dungeon/room_knobs_test.tscn` only if interior math can run without playground

## Headless checks

- Interior cell count ≥ 4× committed dungeon AABB area (cliff excluded).
- Dungeon AABB flush to east interior; fully inside interior.
- Every cliff neighbor of an interior edge is a cliff catalog cell; corners exist.
- West spawn cells are interior, not dungeon, not cliff.
- Entrance world position is inside the east dungeon.
- No outside tile on dungeon or cliff cells (once T011 exists).
- Tree positions ⊆ eligible set; density in range (once T012 exists).
- `clamp` / `is_world_position_in_interior` rejects a point past the ring.

## Play pass (host + client)

- Paper Pusher and DM both stop at the cliff (north, south, east, west).
- Projectiles die on cliffs.
- Late join: same map; client log clean (`ERR_BUG` / `has_node` / invalid synchronizer).
- Homes stay inside the interior.

## Requirements

- Independent Test section of US-024
- Testing skill: new tests under `test_harness/procedural_dungeon/` as Node + `.tscn` that quit on success

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** a host+client play of the independent test, **When** both roles walk the ring, **Then** neither leaves the interior and the joiner sees the same layout.

## Notes

Do not claim the story done until this task’s headless suite passes and the play pass is run or explicitly called out as not run.

Headless suite: `test_harness/procedural_dungeon/us024_independent_test.tscn` plus `us024_run_harness.sh`.

Play pass **not run** this task: no host+client playground session for walking the cliff ring, projectile cliff hits, late-join client log, or in-game home fit.
