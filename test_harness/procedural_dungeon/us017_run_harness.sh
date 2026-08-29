#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

# US-017 T009 two-window play pass (host + client):
# Fight the exit boss (south placeholder OK). Death unlocks HUD blizzard icon; can appears.
# Cast on Reality home: ice overlay, PP walks through slowed (US-003 T011; no wall, no push-out),
# buildings won't place, factories tick slower. Second window matches pocket, slow, and factory
# timing. Expire clears ice and speeds. QA owns the play pass; this script is headless only.
# Do not require cozy (US-020), cube (US-019), or fireball (US-018). Do not fail if PP is inside
# the pocket (T011). Do not require a game-over path.

# Godot --quit-after exits 0 even when a scene fails to parse.
# Success is the scene's actual passed print, not the engine exit code.
SCENES=(
	"test_harness/procedural_dungeon/us017_boss_spawn_test.tscn|US-017 T001/T002 boss spawn test passed"
	"test_harness/procedural_dungeon/us017_boss_combat_test.tscn|US-017 T003 boss combat test passed"
	"test_harness/procedural_dungeon/us017_boss_aggro_test.tscn|US-017 T003 boss aggro test passed"
	"test_harness/procedural_dungeon/us017_boss_unlock_test.tscn|US-017 T004 boss unlock test passed"
	"test_harness/procedural_dungeon/us017_blizzard_cast_test.tscn|US-017 T005 blizzard cast test passed"
	"test_harness/procedural_dungeon/us017_blizzard_factory_test.tscn|US-017 T006 blizzard factory test passed"
	"test_harness/procedural_dungeon/us017_blizzard_hud_test.tscn|US-017 T007 blizzard HUD test passed"
	"test_harness/procedural_dungeon/us017_blizzard_replicate_test.tscn|US-017 T008 blizzard replicate test passed"
	"test_harness/procedural_dungeon/us017_blizzard_test.tscn|US-017 T009 independent test passed"
	"test_harness/procedural_dungeon/skeleton_only_spawns_test.tscn|Skeleton-only spawns test passed"
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
echo "US-017 T001/T002/T003/T004/T005/T006/T007/T008/T009 headless harness passed"
