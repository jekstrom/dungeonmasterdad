#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

SCENES=(
	test_harness/procedural_dungeon/us030_item_row_flags_test.tscn
	test_harness/procedural_dungeon/us030_slotted_bag_test.tscn
	test_harness/procedural_dungeon/us030_hud_rows_test.tscn
	test_harness/procedural_dungeon/us030_hotkeys_test.tscn
	test_harness/procedural_dungeon/us030_use_slot_test.tscn
	test_harness/procedural_dungeon/us030_hold_channel_test.tscn
	test_harness/procedural_dungeon/us030_drag_swap_test.tscn
	test_harness/procedural_dungeon/us030_replicate_slots_test.tscn
	test_harness/procedural_dungeon/us030_independent_test.tscn
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
echo "US-030 headless harness passed"
