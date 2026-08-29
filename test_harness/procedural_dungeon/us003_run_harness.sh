#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

SCENES=(
	test_harness/procedural_dungeon/us003_fantasy_home_test.tscn
	test_harness/procedural_dungeon/us003_pocket_contract_test.tscn
	test_harness/procedural_dungeon/us003_exclusion_test.tscn
	test_harness/procedural_dungeon/us003_dm_occupancy_test.tscn
	test_harness/procedural_dungeon/us003_building_reject_test.tscn
	test_harness/procedural_dungeon/us003_skeleton_allow_test.tscn
	test_harness/procedural_dungeon/us003_claim_replicate_test.tscn
	test_harness/procedural_dungeon/us003_fantasy_claim_test.tscn
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
echo "US-003 headless harness passed"
echo "US-003 two-window play pass not run (QA owns it)"
