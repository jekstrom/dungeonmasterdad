#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

SCENES=(
	test_harness/procedural_dungeon/us024_map_bounds_test.tscn
	test_harness/procedural_dungeon/us024_cliff_tile_test.tscn
	test_harness/procedural_dungeon/us024_interior_size_test.tscn
	test_harness/procedural_dungeon/us024_dungeon_east_flush_test.tscn
	test_harness/procedural_dungeon/us024_cliff_ring_test.tscn
	test_harness/procedural_dungeon/us024_player_cliff_clamp_test.tscn
	test_harness/procedural_dungeon/us024_actors_and_west_spawn_test.tscn
	test_harness/procedural_dungeon/us024_dm_entrance_spawn_test.tscn
	test_harness/procedural_dungeon/us024_outside_fill_test.tscn
	test_harness/procedural_dungeon/us024_tree_scatter_test.tscn
	test_harness/procedural_dungeon/us024_zone_clip_test.tscn
	test_harness/procedural_dungeon/us024_map_late_join_test.tscn
	test_harness/procedural_dungeon/us024_independent_test.tscn
)

failed=0
for scene in "${SCENES[@]}"; do
	echo "=== ${scene} ==="
	if ! godot --path "$ROOT" --headless --quit-after 60 "$scene"; then
		echo "FAIL ${scene}"
		failed=1
	fi
done

if [[ "$failed" -ne 0 ]]; then
	exit 1
fi
echo "US-024 headless harness passed"
