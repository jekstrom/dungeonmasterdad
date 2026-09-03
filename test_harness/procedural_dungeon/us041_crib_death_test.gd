extends Node

func _ready() -> void:
	await get_tree().process_frame
	if not await _run_suite():
		return
	print("US-041 crib death test passed")
	get_tree().quit(0)


func _run_suite() -> bool:
	DmUnlocks.reset_unlocks()
	DmManager._crib_death_elapsed = 0.0
	if DmManager.is_crib_death_owned():
		return _fail("US-041 T001: crib_death must start unowned")

	var level_script: Script = load("res://_globals/level_manager.gd") as Script
	var level := Node2D.new()
	level.set_script(level_script)
	add_child(level)
	await get_tree().process_frame
	var bounds = level.get_map_bounds()
	bounds.commit_interior(Rect2i(10, 10, 20, 16))
	level._overworld_dungeon_aabb = Rect2i(18, 14, 8, 8)
	level._overworld_exit_cell = Vector2i(18, 18)
	if not level.has_map_bounds():
		return _fail("US-041: map bounds commit failed")

	var expected: Vector2 = DungeonGrid.to_world_center(Vector2i(17, 18))
	var landing: Vector2 = level.dungeon_exit_landing_world()
	if not landing.is_equal_approx(expected):
		return _fail("US-041: exit landing want %s got %s" % [expected, landing])
	if not DmManager.crib_death_exit_world().is_equal_approx(expected):
		return _fail("US-041: DmManager exit world mismatch")

	if DmManager.try_spawn_crib_death_gremlin() != null:
		return _fail("US-041: unowned must not spawn")
	if get_tree().get_nodes_in_group("gremlins").size() != 0:
		return _fail("US-041: unowned must leave gremlin group empty")

	DmManager._process(60.0)
	if get_tree().get_nodes_in_group("gremlins").size() != 0:
		return _fail("US-041: unowned timer must not spawn")

	DmUnlocks.dm_unlocks["crib_death"] = true
	if not DmManager.is_crib_death_owned():
		return _fail("US-041 T001: force-own must set crib_death owned")

	var spawn_root := Node2D.new()
	spawn_root.name = "SpawnRoot"
	add_child(spawn_root)
	var spawner: Node = (load("res://scripts/multiplayer_spawner.gd") as Script).new()
	spawner.gremlin = load("res://monsters/gremlin.tscn")
	spawn_root.add_child(spawner)
	spawner.spawn_path = NodePath("..")
	await get_tree().process_frame

	var node: Node = DmManager.try_spawn_crib_death_gremlin()
	if node == null:
		return _fail("US-041: owned spawn must return a gremlin")
	if not (node is Gremlin):
		return _fail("US-041: spawned node must be Gremlin")
	var gremlin: Gremlin = node as Gremlin
	if not is_equal_approx(gremlin.lifetime_sec, DmManager.CRIB_DEATH_LIFETIME_SEC):
		return _fail("US-041: crib gremlin lifetime must be 15s, got %s" % gremlin.lifetime_sec)
	await get_tree().process_frame
	if not gremlin.position.is_equal_approx(expected):
		return _fail("US-041: crib gremlin must spawn at exit landing %s got %s" % [expected, gremlin.position])
	if gremlin.position.is_equal_approx(Vector2.ZERO):
		return _fail("US-041: crib gremlin must not spawn at origin")

	gremlin._physics_process(14.9)
	if gremlin._dying:
		return _fail("US-041: crib gremlin must live until 15s")
	gremlin._physics_process(0.2)
	if not gremlin._dying:
		return _fail("US-041: crib gremlin must die at 15s")

	DmUnlocks.dm_unlocks["crib_death"] = false
	var after_lock: int = get_tree().get_nodes_in_group("gremlins").size()
	if DmManager.try_spawn_crib_death_gremlin() != null:
		return _fail("US-041: lock mid-match must stop auto-spawn")
	if get_tree().get_nodes_in_group("gremlins").size() != after_lock:
		return _fail("US-041: lock must not spawn another gremlin")

	return true


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
