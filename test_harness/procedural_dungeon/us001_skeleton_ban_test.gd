extends Node

func _ready() -> void:
	PlayerManager.reality_level = 0
	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	level.add_to_group("level_manager")
	add_child(level)
	await get_tree().process_frame

	var interior := Rect2i(0, 0, 16, 10)
	var dungeon := Rect2i(8, 2, 8, 6)
	level.apply_map_interior(interior, dungeon)
	await get_tree().process_frame

	var reality: RealityZone = load("res://zones/reality_zone.tscn").instantiate()
	reality.add_to_group("RealityZone")
	add_child(reality)
	await get_tree().process_frame

	var home_cell: Vector2i = reality.home_rect.position
	var home_world: Vector2 = DungeonGrid.to_world_center(home_cell)
	var dungeon_cell := Vector2i(dungeon.position.x + 1, dungeon.position.y + 1)
	var dungeon_world: Vector2 = DungeonGrid.to_world_center(dungeon_cell)
	if reality.is_claimed_cell(dungeon_cell):
		push_error("US-001 T007: dungeon fixture must start unclaimed")
		get_tree().quit(1)
		return

	if not RealityClaim.should_reject_skeleton_spawn(get_tree(), RealityClaim.SKELETON_SCENE_PATH, home_world):
		push_error("US-001 T007: skeleton spawn on home must reject")
		get_tree().quit(1)
		return
	if RealityClaim.should_reject_skeleton_spawn(get_tree(), "res://monsters/goblin.tscn", home_world):
		push_error("US-001 T007: goblin spawn must not use skeleton ban")
		get_tree().quit(1)
		return
	if RealityClaim.should_reject_skeleton_spawn(get_tree(), RealityClaim.SKELETON_SCENE_PATH, dungeon_world):
		push_error("US-001 T007: dungeon skeleton spawn must be allowed without a pocket")
		get_tree().quit(1)
		return

	var skeleton: Skeleton = load("res://monsters/skeleton/skeleton.tscn").instantiate()
	add_child(skeleton)
	skeleton.global_position = home_world
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_instance_valid(skeleton) or not skeleton._dying:
		push_error("US-001 T007: skeleton in Reality home must despawn")
		get_tree().quit(1)
		return

	var dungeon_skel: Skeleton = load("res://monsters/skeleton/skeleton.tscn").instantiate()
	add_child(dungeon_skel)
	dungeon_skel.global_position = dungeon_world
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_instance_valid(dungeon_skel) or dungeon_skel._dying:
		push_error("US-001 T007: dungeon skeleton must live without Reality claim")
		get_tree().quit(1)
		return

	var goblin: Node2D = load("res://monsters/goblin.tscn").instantiate() as Node2D
	var knight: Node2D = load("res://monsters/knight/knight.tscn").instantiate() as Node2D
	add_child(goblin)
	add_child(knight)
	goblin.global_position = home_world
	knight.global_position = home_world
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_instance_valid(goblin) or goblin.get("_dying") == true:
		push_error("US-001 T007: goblin must not be banned from Reality")
		get_tree().quit(1)
		return
	if not is_instance_valid(knight) or knight.get("_dying") == true:
		push_error("US-001 T007: knightling must not be banned from Reality")
		get_tree().quit(1)
		return

	var pocket_id: int = reality.spawn_pocket(dungeon_cell, Vector2i(2, 2), 8.0)
	if pocket_id < 0:
		push_error("US-001 T007: pocket over dungeon failed")
		get_tree().quit(1)
		return
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_instance_valid(dungeon_skel) or not dungeon_skel._dying:
		push_error("US-001 T007: pocket covering a skeleton must despawn it")
		get_tree().quit(1)
		return

	var edge: Vector2i = Vector2i(reality.home_rect.end.x, home_cell.y)
	if reality.is_claimed_cell(edge):
		push_error("US-001 T007: growth fixture must start outside home")
		get_tree().quit(1)
		return
	var growth_skel: Skeleton = load("res://monsters/skeleton/skeleton.tscn").instantiate()
	add_child(growth_skel)
	growth_skel.global_position = DungeonGrid.to_world_center(edge)
	await get_tree().physics_frame
	if not is_instance_valid(growth_skel) or growth_skel._dying:
		push_error("US-001 T007: skeleton east of home must live before growth")
		get_tree().quit(1)
		return
	PlayerManager.reality_level = 4
	reality.on_level_changed(4)
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_instance_valid(growth_skel) or not growth_skel._dying:
		push_error("US-001 T007: home growth covering a skeleton must despawn it")
		get_tree().quit(1)
		return

	print("US-001 T007 skeleton ban test passed")
	get_tree().quit(0)
