#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

SCENES=(
	test_harness/procedural_dungeon/us010_office_max_test.tscn
)

failed=0
for scene in "${SCENES[@]}"; do
	echo "=== ${scene} ==="
	out="$(godot --path "$ROOT" --headless --quit-after 120 "$scene" 2>&1)" || {
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
	if ! echo "$out" | grep -Eq "US-010 T002/T003 office max test passed|US-010 T002-T007 office max test passed"; then
		echo "FAIL ${scene} (no pass line)"
		failed=1
	fi
done

if [[ "$failed" -ne 0 ]]; then
	exit 1
fi
echo "US-010 headless harness passed"
echo "US-010 two-window play pass not run (QA owns it)"
