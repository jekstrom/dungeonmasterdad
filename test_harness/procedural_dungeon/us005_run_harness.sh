#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

SCENES=(
	test_harness/procedural_dungeon/us005_staple_fire_test.tscn
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
echo "US-005 headless harness passed"
echo "US-005 two-window play pass not run (QA owns it)"
