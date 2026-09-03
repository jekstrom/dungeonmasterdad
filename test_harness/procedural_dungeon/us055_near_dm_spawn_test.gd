extends Node

const Catalog = preload("res://dm/dm_ability_catalog.gd")
const NearSpawn = preload("res://scripts/dm_near_spawn_picker.gd")
## US-055: near-DM Chebyshev [1,3] picker, walkable-only, inland bias, fail-closed, multi-knight, crib path untouched.

func _ready() -> void:
	await get_tree().process_frame
	var rng := RandomNumberGenerator.new()
	rng.seed = 55

	# --- T001 picker band / walkable ---
	var level_script: Script = load("res://_globals/level_manager.gd") as Script
	var level := Node2D.new()
	level.set_script(level_script)
	add_child(level)
	await get_tree().process_frame
	var bounds = level.get_map_bounds()
	bounds.commit_interior(Rect2i(10, 10, 20, 16))
	if not level.has_map_bounds():
		return _fail("US-055: map bounds commit failed")

	var dm_cell := Vector2i(18, 18)
	var dm_world: Vector2 = DungeonGrid.to_world_center(dm_cell)
	var seen: Dictionary = {}
	for _i in range(40):
		var pick: Dictionary = NearSpawn.pick_near_dm(get_tree(), dm_world, rng)
		if not bool(pick.get("ok", false)):
			return _fail("US-055: picker failed on open ground")
		var cell: Vector2i = pick["cell"]
		var d: int = DungeonGrid.chebyshev(cell, dm_cell)
		if d < 1 or d > 3:
			return _fail("US-055: cell %s chebyshev %d not in [1,3]" % [cell, d])
		if not bounds.is_world_position_walkable(pick["world"]):
			return _fail("US-055: picked non-walkable %s" % cell)
		if cell == dm_cell:
			return _fail("US-055: must not spawn on DM cell")
		seen[cell] = true
	if seen.size() < 3:
		return _fail("US-055: expected varied cells, got %d unique" % seen.size())

	# Soft inland bias: over many rolls, average inland score of picks should beat
	# uniform mean of rim-heavy set (or simply: more inland than pure edge).
	var inland_hits := 0
	var edge_hits := 0
	for _i in range(80):
		var pick2: Dictionary = NearSpawn.pick_near_dm(get_tree(), dm_world, rng)
		var c: Vector2i = pick2["cell"]
		var score: float = NearSpawn._inland_score(c, level)
		if score >= 3.0:
			inland_hits += 1
		if score <= 1.0:
			edge_hits += 1
	if inland_hits <= edge_hits:
		return _fail("US-055: inland bias weak (inland=%d edge=%d)" % [inland_hits, edge_hits])

	# Fail closed: DM in a 1-cell island with no [1,3] walkable ring.
	bounds.commit_interior(Rect2i(50, 50, 1, 1))
	var island_world: Vector2 = DungeonGrid.to_world_center(Vector2i(50, 50))
	var fail_pick: Dictionary = NearSpawn.pick_near_dm(get_tree(), island_world, rng)
	if bool(fail_pick.get("ok", false)):
		return _fail("US-055: must fail closed when no eligible cell")

	# --- Mana fail-closed via DmManager (no spend on fail) ---
	# dm==null → anchor (0,0); 1×1 interior at origin leaves band non-walkable.
	bounds.commit_interior(Rect2i(0, 0, 1, 1))
	DmManager.set_mana(100)
	var mana_before: int = DmManager.current_mana
	DmManager._server_request_cast(Catalog.GREMLIN)
	if DmManager.current_mana != mana_before:
		return _fail("US-055: fail-closed must not spend mana (mana %d → %d)" % [mana_before, DmManager.current_mana])

	# Restore open interior for multi-knight independence
	bounds.commit_interior(Rect2i(10, 10, 20, 16))
	DmUnlocks.dm_unlocks["chain_lightning"] = true
	DmUnlocks.dm_unlocks[Catalog.KNIGHTLING] = true
	var cells_multi: Array[Vector2i] = []
	for _i in range(3):
		var p: Dictionary = NearSpawn.pick_near_dm(get_tree(), dm_world, rng)
		if not bool(p.get("ok", false)):
			return _fail("US-055: chain lightning independent pick failed")
		cells_multi.append(p["cell"])
	# Not required to all differ, but each must be in-band (already checked by picker).
	for cell in cells_multi:
		var d2: int = DungeonGrid.chebyshev(cell, dm_cell)
		if d2 < 1 or d2 > 3:
			return _fail("US-055: multi-knight cell out of band")

	# Crib / exit path must remain available and NOT use near-DM helper as sole API.
	var spawner_src := FileAccess.get_file_as_string("res://scripts/multiplayer_spawner.gd")
	if spawner_src.is_empty():
		return _fail("US-055: multiplayer_spawner missing")
	if spawner_src.find("func spawn_gremlin_at") == -1:
		return _fail("US-055: spawn_gremlin_at must exist for Crib Death exit (unchanged path)")
	if spawner_src.find("func try_spawn_goblin_near_dm") == -1:
		return _fail("US-055: goblin near-DM spawn missing")
	if spawner_src.find("func try_spawn_gremlin_near_dm") == -1 or spawner_src.find("func try_spawn_knights_near_dm") == -1:
		return _fail("US-055: gremlin/knight near-DM spawn missing")

	# Ability catalog includes goblin
	if not Catalog.is_known(Catalog.GOBLIN):
		return _fail("US-055: GOBLIN ability missing from catalog")

	print("US-055 near-DM spawn test passed")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
