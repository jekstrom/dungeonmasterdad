extends Node

func _ready() -> void:
	PlayerManager.reality_level = 0
	DmManager.fantasy_level = 0
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
	var fantasy: FantasyZone = load("res://zones/fantasy_zone.tscn").instantiate()
	add_child(fantasy)
	await get_tree().process_frame

	var dungeon_cell := Vector2i(dungeon.position.x + 1, dungeon.position.y + 1)
	var dungeon_world: Vector2 = DungeonGrid.to_world_center(dungeon_cell)
	if not fantasy.is_claimed_cell(dungeon_cell):
		push_error("US-003 T008: dungeon cell should start in Fantasy home")
		get_tree().quit(1)
		return
	if reality.is_claimed_cell(dungeon_cell):
		push_error("US-003 T008: dungeon cell must not start Reality-claimed")
		get_tree().quit(1)
		return
	if RealityClaim.should_despawn_skeleton(get_tree(), dungeon_world):
		push_error("US-003 T008: Fantasy-only cell must allow skeletons")
		get_tree().quit(1)
		return
	if RealityClaim.should_reject_skeleton_spawn(get_tree(), RealityClaim.SKELETON_SCENE_PATH, dungeon_world):
		push_error("US-003 T008: Fantasy-only spawn must not reject skeletons")
		get_tree().quit(1)
		return

	var skel: Skeleton = load("res://monsters/skeleton/skeleton.tscn").instantiate()
	add_child(skel)
	skel.global_position = dungeon_world
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_instance_valid(skel) or skel._dying:
		push_error("US-003 T008: skeleton in Fantasy home must live")
		get_tree().quit(1)
		return

	var goblin: Node2D = load("res://monsters/goblin.tscn").instantiate() as Node2D
	add_child(goblin)
	goblin.global_position = dungeon_world
	await get_tree().physics_frame
	if not is_instance_valid(goblin) or goblin.get("_dying") == true:
		push_error("US-003 T008: goblin must be unchanged")
		get_tree().quit(1)
		return

	var reality_home: Vector2 = DungeonGrid.to_world_center(reality.home_rect.position)
	var fantasy_pocket: int = fantasy.spawn_pocket(reality.home_rect.position, Vector2i(2, 2), 8.0)
	if fantasy_pocket < 0:
		push_error("US-003 T008: Fantasy pocket over Reality home failed")
		get_tree().quit(1)
		return
	if RealityClaim.should_despawn_skeleton(get_tree(), reality_home):
		push_error("US-003 T008: Fantasy pocket must override Reality home for skeletons")
		get_tree().quit(1)
		return
	var pocket_skel: Skeleton = load("res://monsters/skeleton/skeleton.tscn").instantiate()
	add_child(pocket_skel)
	pocket_skel.global_position = reality_home
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_instance_valid(pocket_skel) or pocket_skel._dying:
		push_error("US-003 T008: skeleton in Fantasy pocket over Reality home must live")
		get_tree().quit(1)
		return

	var reality_pocket: int = reality.spawn_pocket(dungeon_cell, Vector2i(2, 2), 8.0)
	if reality_pocket < 0:
		push_error("US-003 T008: Reality pocket over dungeon failed")
		get_tree().quit(1)
		return
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_instance_valid(skel) or not skel._dying:
		push_error("US-003 T008: Reality pocket must still ban the dungeon skeleton")
		get_tree().quit(1)
		return

	fantasy.expire_pocket(fantasy_pocket)
	reality.expire_pocket(reality_pocket)
	PlayerManager.reality_level = 10000
	DmManager.fantasy_level = 10000
	reality.on_level_changed(10000)
	fantasy.on_level_changed(10000)
	var overlap: Vector2 = DungeonGrid.to_world_center(Vector2i(8, 5))
	if not reality.is_claimed_world(overlap) or not fantasy.is_claimed_world(overlap):
		push_error("US-003 T008: grown homes should overlap")
		get_tree().quit(1)
		return
	if not RealityClaim.should_despawn_skeleton(get_tree(), overlap):
		push_error("US-003 T008: home overlap with no pocket must still ban skeletons")
		get_tree().quit(1)
		return
	var overlap_skel: Skeleton = load("res://monsters/skeleton/skeleton.tscn").instantiate()
	add_child(overlap_skel)
	overlap_skel.global_position = overlap
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_instance_valid(overlap_skel) or not overlap_skel._dying:
		push_error("US-003 T008: skeleton in home overlap must despawn")
		get_tree().quit(1)
		return

	PlayerManager.reality_level = 0
	DmManager.fantasy_level = 0
	print("US-003 T008 skeleton allow test passed")
	get_tree().quit(0)
