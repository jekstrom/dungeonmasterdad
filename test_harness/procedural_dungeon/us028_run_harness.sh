#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

# US-028 T005 two-window play pass (host + client):
# Fountain in a dungeon room charges, splashes Baja dew, knocks back on overlap,
# slick floor slides then expires. Second window matches splash, knockback, and
# slick rect/remaining. Boss does not fire this. QA owns the play pass; this
# script is headless only.

SCENES=(
	"test_harness/procedural_dungeon/us028_fountain_doodad_test.tscn|US-028 T001 fountain doodad test passed"
	"test_harness/procedural_dungeon/us028_periodic_splash_test.tscn|US-028 T002 periodic splash test passed"
	"test_harness/procedural_dungeon/us028_dew_slick_test.tscn|US-028 T003 dew slick test passed"
	"test_harness/procedural_dungeon/us028_fountain_replicate_test.tscn|US-028 T004 fountain replicate test passed"
	"test_harness/procedural_dungeon/us028_fountain_slick_test.tscn|US-028 T005 independent test passed"
)

failed=0
for entry in "${SCENES[@]}"; do
	scene="${entry%%|*}"
	needle="${entry#*|}"
	echo "=== ${scene} ==="
	log="$(mktemp)"
	rc=0
	godot --path "$ROOT" --headless --quit-after 90 "$scene" >"$log" 2>&1 || rc=$?
	cat "$log"
	if [[ "$rc" -ne 0 ]]; then
		echo "FAIL ${scene} (godot exit ${rc})"
		failed=1
	elif ! grep -F -q -- "$needle" "$log"; then
		echo "FAIL ${scene} (missing passed line: ${needle})"
		failed=1
	fi
	rm -f "$log"
done

if [[ "$failed" -ne 0 ]]; then
	exit 1
fi
echo "US-028 T001/T002/T003/T004/T005 headless harness passed"
