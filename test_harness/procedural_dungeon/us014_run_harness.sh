#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

SCENES=(
	test_harness/procedural_dungeon/us014_mana_pool_test.tscn
	test_harness/procedural_dungeon/us014_ability_catalog_test.tscn
	test_harness/procedural_dungeon/us014_try_cast_test.tscn
	test_harness/procedural_dungeon/us014_summon_spend_test.tscn
	test_harness/procedural_dungeon/us014_fireball_spend_test.tscn
	test_harness/procedural_dungeon/us014_dew_effect_test.tscn
	test_harness/procedural_dungeon/us014_mana_hud_test.tscn
	test_harness/procedural_dungeon/us014_start_room_dew_test.tscn
	test_harness/procedural_dungeon/us014_independent_test.tscn
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
echo "US-014 headless harness passed"
