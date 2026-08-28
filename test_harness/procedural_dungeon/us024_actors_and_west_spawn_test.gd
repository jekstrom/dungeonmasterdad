extends Node

func _ready() -> void:
	var bounds := MapBounds.new()
	var interior := Rect2i(0, 0, 8, 6)
	bounds.commit_interior(interior)
	var dungeon := Rect2i(4, 1, 4, 4)
	var strip: Array[Vector2i] = bounds.west_spawn_strip_cells(dungeon)
	if strip.is_empty():
		push_error("US-024 T009: west spawn strip empty")
		get_tree().quit(1)
		return
	for cell in strip:
		if cell.x != 0:
			push_error("US-024 T009: west strip cell not on west edge %s" % cell)
			get_tree().quit(1)
			return
		if dungeon.has_point(cell):
			push_error("US-024 T009: west strip overlapped dungeon %s" % cell)
			get_tree().quit(1)
			return
		if bounds.is_cliff_cell(cell):
			push_error("US-024 T009: west strip on cliff %s" % cell)
			get_tree().quit(1)
			return
		if not bounds.is_interior_cell(cell):
			push_error("US-024 T009: west strip not interior %s" % cell)
			get_tree().quit(1)
			return
	var spawn_world: Vector2 = bounds.west_spawn_world(0, dungeon)
	if spawn_world.is_equal_approx(Vector2.ZERO):
		push_error("US-024 T009: must not spawn at world origin")
		get_tree().quit(1)
		return
	if not bounds.is_world_position_in_interior(spawn_world):
		push_error("US-024 T009: spawn world not interior")
		get_tree().quit(1)
		return

	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	add_child(level)
	await get_tree().process_frame
	level.apply_map_interior(interior)
	var first: Vector2 = level.take_west_spawn_world()
	var second: Vector2 = level.take_west_spawn_world()
	if first.is_equal_approx(second):
		push_error("US-024 T009: sequential west spawns should advance along the strip")
		get_tree().quit(1)
		return

	var monster := CharacterBody2D.new()
	monster.add_to_group("generated_dungeon_monsters")
	add_child(monster)
	monster.global_position = Vector2(-400, 64)
	monster.velocity = Vector2(-400, 0)
	level.enforce_body_interior(monster)
	if not level.map_bounds.is_world_position_walkable(monster.global_position):
		push_error("US-024 T008: monster was not clamped to walkable bounds")
		get_tree().quit(1)
		return

	var outside := Vector2(-400, 64)
	if bounds.is_world_position_walkable(outside):
		push_error("US-024 T008: expected far void probe to be non-walkable")
		get_tree().quit(1)
		return
	var clamped: Vector2 = bounds.clamp_world_to_interior(outside)
	if not bounds.is_world_position_walkable(clamped):
		push_error("US-024 T008: projectile clamp point must be walkable")
		get_tree().quit(1)
		return

	print("US-024 T008/T009 actors and west spawn test passed")
	get_tree().quit(0)
