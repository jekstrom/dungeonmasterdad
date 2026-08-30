#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

SCENES=(
	test_harness/procedural_dungeon/us009_form_items_test.tscn
	test_harness/procedural_dungeon/us009_create_form_test.tscn
	test_harness/procedural_dungeon/us009_fill_channel_test.tscn
	test_harness/procedural_dungeon/us009_fill_outcomes_test.tscn
	test_harness/procedural_dungeon/us009_irs_building_test.tscn
	test_harness/procedural_dungeon/us009_file_tax_test.tscn
	test_harness/procedural_dungeon/us009_replicate_test.tscn
	test_harness/procedural_dungeon/us009_independent_test.tscn
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
	if echo "$out" | grep -Eq "SCRIPT ERROR: Parse Error|Failed to load script"; then
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
echo "US-009 headless harness passed"
