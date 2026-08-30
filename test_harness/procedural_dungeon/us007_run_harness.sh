#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

SCENES=(
	test_harness/procedural_dungeon/us007_iron_item_test.tscn
	test_harness/procedural_dungeon/us007_mine_doodad_test.tscn
	test_harness/procedural_dungeon/us007_mine_harvest_test.tscn
	test_harness/procedural_dungeon/us007_iron_yield_test.tscn
	test_harness/procedural_dungeon/us007_mine_lockout_test.tscn
	test_harness/procedural_dungeon/us007_mine_placement_test.tscn
	test_harness/procedural_dungeon/us007_building_cost_test.tscn
	test_harness/procedural_dungeon/us007_replicate_test.tscn
	test_harness/procedural_dungeon/us007_independent_test.tscn
)

failed=0
for scene in "${SCENES[@]}"; do
	echo "=== ${scene} ==="
	out="$(godot --path "$ROOT" --headless --quit-after 60 "$scene" 2>&1)" || {
		echo "$out"
		echo "FAIL ${scene}"
		failed=1
		continue
	}
	echo "$out"
	if echo "$out" | grep -Eq "SCRIPT ERROR: Parse Error|Failed to load script|ERROR: Failed to load"; then
		echo "FAIL ${scene} (script error)"
		failed=1
		continue
	fi
	if ! echo "$out" | grep -q "passed"; then
		echo "FAIL ${scene} (no pass line)"
		failed=1
	fi
done

if [[ "$failed" -ne 0 ]]; then
	exit 1
fi
echo "US-007 headless harness passed"
