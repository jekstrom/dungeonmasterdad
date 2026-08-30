#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

# US-031 T007 two-window play pass (host + client):
# Host as DM with blizzard already unlocked (or kill the US-017 boss once). Mana from Dew if needed.
# Cast on Reality home: ice on the ground, snow/icicles falling in the rect, PP walks through
# slowed (US-003 T011; no wall, no push-out), buildings won't place, factories tick slower.
# Second window matches pocket, ground ice, slow, and factory timing (flake timing need not match).
# Expire clears ice, fall VFX, and speeds. QA owns the play pass; this script is headless only.
# Do not require the Baja Blast fight, cozy, cube, or fireball. Do not fail if PP is inside the pocket.

# Godot --quit-after exits 0 even when a scene fails to parse.
# Success is the scene's actual passed print, not the engine exit code.
SCENES=(
	"test_harness/procedural_dungeon/us017_blizzard_cast_test.tscn|US-017 T005 blizzard cast test passed"
	"test_harness/procedural_dungeon/us017_blizzard_factory_test.tscn|US-017 T006 blizzard factory test passed"
	"test_harness/procedural_dungeon/us017_blizzard_hud_test.tscn|US-017 T007 blizzard HUD test passed"
	"test_harness/procedural_dungeon/us017_blizzard_replicate_test.tscn|US-017 T008 blizzard replicate test passed"
	"test_harness/procedural_dungeon/us017_blizzard_test.tscn|US-017 T009 independent test passed"
	"test_harness/procedural_dungeon/us031_cast_gate_test.tscn|US-031 T001 cast gate test passed"
	"test_harness/procedural_dungeon/us031_blizzard_vfx_test.tscn|US-031 T008 blizzard vfx test passed"
	"test_harness/procedural_dungeon/us031_independent_test.tscn|US-031 T007 independent test passed"
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
	elif ! grep -F -q -- "$needle" "$log"; then
		echo "FAIL ${scene} (missing passed line: ${needle})"
		failed=1
	fi
	rm -f "$log"
done

if [[ "$failed" -ne 0 ]]; then
	exit 1
fi
echo "US-031 T001/T002/T003/T004/T005/T006/T007/T008 headless harness passed"
