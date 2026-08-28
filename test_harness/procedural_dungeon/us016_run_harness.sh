#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

SCENES=(
	test_harness/procedural_dungeon/us016_pickup_placement_test.tscn
	test_harness/procedural_dungeon/us016_pickup_count_knobs_test.tscn
	test_harness/procedural_dungeon/us016_dice_effect_test.tscn
	test_harness/procedural_dungeon/us016_knightling_unlock_gate_test.tscn
	test_harness/procedural_dungeon/us016_dew_unlock_test.tscn
	test_harness/procedural_dungeon/us016_knightling_hud_test.tscn
	test_harness/procedural_dungeon/us016_fantasy_home_growth_test.tscn
	test_harness/procedural_dungeon/us016_unlock_replication_test.tscn
	test_harness/procedural_dungeon/us016_independent_test.tscn
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
echo "US-016 headless harness passed"
