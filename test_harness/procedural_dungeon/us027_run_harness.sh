#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

# US-027 two-window play pass (host + client):
# Readable arm-point tell, neon Baja teal piercing stream, DM can be hit.
# Peer matches the lane and hit. Distinct from US-017 blast spit.
# QA owns the play pass; this script is headless only.
# Godot --quit-after exits 0 even when a scene fails to parse.
# Success is the scene's actual passed print, not the engine exit code.

SCENES=(
	"test_harness/procedural_dungeon/us027_carbonated_jet_test.tscn|US-027 T001/T002/T003/T004 carbonated jet test passed"
	"test_harness/procedural_dungeon/us017_boss_combat_test.tscn|US-017 T003 boss combat test passed"
	"test_harness/procedural_dungeon/us017_boss_aggro_test.tscn|US-017 T003 boss aggro test passed"
	"test_harness/procedural_dungeon/us005_staple_fire_test.tscn|US-005 T001-T003 staple fire test passed"
)

failed=0
for entry in "${SCENES[@]}"; do
	scene="${entry%%|*}"
	needle="${entry#*|}"
	echo "=== ${scene} ==="
	log="$(mktemp)"
	rc=0
	godot --path "$ROOT" --headless --quit-after 1800 "$scene" >"$log" 2>&1 || rc=$?
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
echo "US-027 T001/T002/T003/T004 headless harness passed"
echo "US-027 two-window play pass not run (QA owns it)"
