#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
SCENES=(
	"test_harness/procedural_dungeon/us013_gremlin_relocate_test.tscn|US-013 gremlin relocate test passed"
)
failed=0
for entry in "${SCENES[@]}"; do
	scene="${entry%%|*}"
	needle="${entry#*|}"
	echo "=== ${scene} ==="
	log="$(mktemp)"
	rc=0
	godot --path "$ROOT" --headless --quit-after 60 "$scene" >"$log" 2>&1 || rc=$?
	cat "$log"
	if [[ "$rc" -ne 0 ]]; then
		echo "FAIL ${scene} (godot exit ${rc})"
		failed=1
	elif grep -Eq "SCRIPT ERROR: Parse Error|Failed to load script" "$log"; then
		echo "FAIL ${scene} (script error)"
		failed=1
	elif ! grep -F -q -- "$needle" "$log"; then
		echo "FAIL ${scene} (missing: ${needle})"
		failed=1
	fi
	rm -f "$log"
done
if [[ "$failed" -ne 0 ]]; then exit 1; fi
echo "US-013 headless harness passed"
