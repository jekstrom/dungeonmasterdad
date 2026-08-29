#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

SCENES=(
	test_harness/procedural_dungeon/us001_reality_home_test.tscn
	test_harness/procedural_dungeon/us001_pocket_contract_test.tscn
	test_harness/procedural_dungeon/us001_occupancy_test.tscn
	test_harness/procedural_dungeon/us001_building_placement_test.tscn
	test_harness/procedural_dungeon/us001_skeleton_ban_test.tscn
	test_harness/procedural_dungeon/us001_claim_replicate_test.tscn
	test_harness/procedural_dungeon/us001_reality_claim_test.tscn
)

failed=0
for scene in "${SCENES[@]}"; do
	echo "=== ${scene} ==="
	if ! godot --path "$ROOT" --headless --quit-after 180 "$scene"; then
		echo "FAIL ${scene}"
		failed=1
	fi
done

if [[ "$failed" -ne 0 ]]; then
	exit 1
fi
echo "US-001 headless harness passed"
echo "US-001 two-window play pass not run (QA owns it)"
