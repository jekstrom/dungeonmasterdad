#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

SCENES=(
	test_harness/procedural_dungeon/us006_wood_paper_items_test.tscn
	test_harness/procedural_dungeon/us006_tree_harvest_test.tscn
	test_harness/procedural_dungeon/us006_wood_yield_test.tscn
	test_harness/procedural_dungeon/us006_harvest_lockout_test.tscn
	test_harness/procedural_dungeon/us006_deposit_wood_test.tscn
	test_harness/procedural_dungeon/us006_paper_production_test.tscn
	test_harness/procedural_dungeon/us006_replicate_test.tscn
	test_harness/procedural_dungeon/us006_independent_test.tscn
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
echo "US-006 headless harness passed"
