extends RefCounted

const SpawnPopulatorScript = preload("res://scripts/procedural_dungeon/generation/dungeon_spawn_populator.gd")

var host: Node
var _dungeon_scene_builder: DungeonSceneBuilder = DungeonSceneBuilder.new()
var _spawn_populator = SpawnPopulatorScript.new()


func commit(layout_data: DungeonLayoutData) -> Dictionary:
	if not host.multiplayer.is_server():
		return DungeonGenerationTypes.error_payload(
			layout_data.request_id,
			DungeonGenerationTypes.FAILURE_AUTHORITY_VIOLATION,
			"Only server can commit generated dungeons"
		)

	var level_manager: Node = level_manager_or_null()
	if not level_manager:
		_print_region_dump(layout_data)
		return {"ok": true}

	translate_layout_flush_east(layout_data)
	level_manager.begin_generated_dungeon_stage()

	var tile_result: Dictionary = spawn_generated_tiles(layout_data, level_manager)
	if not tile_result.get("ok", false):
		level_manager.rollback_generated_dungeon_stage()
		return tile_result

	var spawn_result: Dictionary = spawn_generated_monsters(layout_data, level_manager)
	if not spawn_result.get("ok", false):
		level_manager.rollback_generated_dungeon_stage()
		return spawn_result

	spawn_generated_fountain(layout_data, level_manager)
	level_manager.commit_generated_dungeon_stage()
	spawn_generated_pickups(layout_data)
	_print_region_dump(layout_data)
	_smoke_check_generated_tiles(layout_data)
	return {"ok": true}


func translate_layout_flush_east(layout_data: DungeonLayoutData) -> void:
	var current: Rect2i = bounds_from_walkable(layout_data.walkable_cells)
	var delta: Vector2i = MapBounds.cell_translation_for_east_flush(current)
	layout_data.translate_cells(delta)


static func bounds_from_walkable(walkable_cells: Array[Vector2i]) -> Rect2i:
	if walkable_cells.is_empty():
		return Rect2i()
	var min_c: Vector2i = walkable_cells[0]
	var max_c: Vector2i = walkable_cells[0]
	for cell in walkable_cells:
		min_c.x = mini(min_c.x, cell.x)
		min_c.y = mini(min_c.y, cell.y)
		max_c.x = maxi(max_c.x, cell.x)
		max_c.y = maxi(max_c.y, cell.y)
	var origin: Vector2i = min_c - Vector2i.ONE
	var size: Vector2i = (max_c - min_c) + Vector2i(3, 3)
	return Rect2i(origin, size)


func level_manager_or_null() -> Node:
	var tree: SceneTree = host.get_tree()
	if tree == null:
		return null
	var current_scene: Node = tree.current_scene
	if current_scene and current_scene.has_method("begin_generated_dungeon_stage"):
		return current_scene
	return tree.get_first_node_in_group("level_manager")


func multiplayer_spawner_or_null() -> Node:
	var tree: SceneTree = host.get_tree()
	if tree == null:
		return null
	var spawners: Array = tree.get_nodes_in_group("multiplayer_spawner")
	if spawners.is_empty():
		return null
	return spawners[0]


func spawn_generated_tiles(layout_data: DungeonLayoutData, level_manager: Node) -> Dictionary:
	var spawner: Node = multiplayer_spawner_or_null()
	if spawner == null or not spawner.has_method("spawn_tile_from_scene_path"):
		var built_scene: Dictionary = _dungeon_scene_builder.build_container(layout_data)
		if not built_scene.get("ok", false):
			return built_scene
		var container: Node2D = built_scene.get("container", null)
		if not container:
			return DungeonGenerationTypes.error_payload(
				layout_data.request_id,
				DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE,
				"Generated dungeon container missing"
			)
		if container.get_parent():
			container.get_parent().remove_child(container)
		host.get_tree().current_scene.add_child(container)
		level_manager.register_staged_generated_node(container)
		return {"ok": true}
	for placement in layout_data.tile_placements:
		var scene_path: String = str(placement.get("tileSourcePath", ""))
		var point: Dictionary = placement.get("position", {})
		var world_position: Vector2 = DungeonGrid.to_world_from_dict(point)
		var variant_id: int = int(placement.get("variantId", -1))
		var wall_frame: int = int(placement.get("wallFrame", -1))
		var tile: Node2D = spawner.spawn_tile_from_scene_path(scene_path, world_position, variant_id, wall_frame)
		if not tile:
			return DungeonGenerationTypes.error_payload(
				layout_data.request_id,
				DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE,
				"Failed to spawn one or more tiles"
			)
		level_manager.register_staged_generated_node(tile)
	return {"ok": true}


func spawn_generated_monsters(layout_data: DungeonLayoutData, level_manager: Node) -> Dictionary:
	var spawner: Node = multiplayer_spawner_or_null()
	if spawner == null or not spawner.has_method("spawn_monster_from_scene_path"):
		return {"ok": true}

	for spawn in layout_data.monster_spawns:
		var position_dict: Dictionary = spawn.get("position", {})
		var world_position: Vector2 = DungeonGrid.to_world_from_dict(position_dict)
		var scene_path: String = str(spawn.get("monsterScenePath", ""))
		if RealityClaim.should_reject_skeleton_spawn(host.get_tree(), scene_path, world_position):
			continue
		var monster: Node2D = spawner.spawn_monster_from_scene_path(
			scene_path,
			world_position,
			str(spawn.get("spawnId", ""))
		)
		if not monster:
			return DungeonGenerationTypes.error_payload(
				layout_data.request_id,
				DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE,
				"Failed to spawn one or more monsters"
			)
		level_manager.register_staged_generated_node(monster)
	return {"ok": true}


func spawn_generated_fountain(layout_data: DungeonLayoutData, level_manager: Node) -> void:
	clear_generated_fountains()
	if layout_data.fountain_cell == DungeonGrid.SENTINEL:
		return
	var packed: PackedScene = load("res://doodads/water_fountain.tscn") as PackedScene
	if packed == null:
		return
	var fountain: Node2D = packed.instantiate() as Node2D
	if fountain == null:
		return
	fountain.name = ("fountain_%d_%d" % [layout_data.fountain_cell.x, layout_data.fountain_cell.y]).validate_node_name()
	fountain.position = DungeonGrid.to_world_center(layout_data.fountain_cell)
	fountain.add_to_group("water_fountain")
	var parent: Node = generated_fountain_parent()
	parent.add_child(fountain)
	if fountain.has_method("configure_room"):
		var cells: Array[Vector2i] = layout_data.fountain_room_cells
		if cells.is_empty():
			cells = _spawn_populator.fountain_room_cells(layout_data)
		fountain.call("configure_room", layout_data.fountain_cell, cells)
	if level_manager and level_manager.has_method("register_staged_generated_node"):
		level_manager.register_staged_generated_node(fountain)


func spawn_generated_pickups(layout_data: DungeonLayoutData) -> void:
	if not host.multiplayer.is_server():
		return
	for pickup in layout_data.item_pickups:
		var item_type: String = str(pickup.get("item_type", ""))
		if item_type.is_empty():
			continue
		var world_position: Vector2 = DungeonGrid.to_world_center(DungeonGrid.cell_from(pickup.get("position", {})))
		SignalBus.on_item_drop.emit({
			"item_type": item_type,
			"position": world_position
		})


func spawn_fountain_from_contract(layout_payload: Dictionary) -> void:
	var raw: Variant = layout_payload.get("fountain", {})
	if not (raw is Dictionary) or (raw as Dictionary).is_empty():
		clear_generated_fountains()
		clear_dew_slicks()
		return
	var cell: Vector2i = DungeonGrid.cell_from(raw)
	var stub := DungeonLayoutData.new()
	stub.fountain_cell = cell
	stub.fountain_room_cells = cells_from_payload((raw as Dictionary).get("cells", []))
	spawn_generated_fountain(stub, null)


func apply_fountain_state(payload: Dictionary) -> void:
	if payload.is_empty() or not payload.has("x"):
		clear_generated_fountains()
		clear_dew_slicks()
		return
	var stub := DungeonLayoutData.new()
	stub.fountain_cell = Vector2i(int(payload.get("x", 0)), int(payload.get("y", 0)))
	stub.fountain_room_cells = cells_from_payload(payload.get("cells", []))
	var existing: Node = first_fountain()
	if existing == null:
		spawn_generated_fountain(stub, null)
		existing = first_fountain()
	elif existing.has_method("configure_room"):
		existing.call("configure_room", stub.fountain_cell, stub.fountain_room_cells)
	if existing and existing.has_method("apply_state"):
		existing.call("apply_state", payload)


func generated_fountain_parent() -> Node:
	var tree: SceneTree = host.get_tree()
	var current: Node = tree.current_scene if tree else null
	if current:
		var tiles: Node = current.get_node_or_null("GeneratedTiles")
		if tiles:
			return tiles
		return current
	return tree.root


func first_fountain() -> Node:
	var tree: SceneTree = host.get_tree()
	if tree == null:
		return null
	var nodes: Array = tree.get_nodes_in_group("water_fountain")
	if nodes.is_empty():
		return null
	return nodes[0]


func clear_generated_fountains() -> void:
	var tree: SceneTree = host.get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("water_fountain"):
		if not is_instance_valid(node):
			continue
		node.remove_from_group("water_fountain")
		var parent: Node = node.get_parent()
		if parent:
			parent.remove_child(node)
		node.queue_free()


func clear_dew_slicks() -> void:
	var tree: SceneTree = host.get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("dew_slick"):
		if not is_instance_valid(node):
			continue
		node.remove_from_group("dew_slick")
		var parent: Node = node.get_parent()
		if parent:
			parent.remove_child(node)
		node.queue_free()


func pack_fountain_state() -> Dictionary:
	var tree: SceneTree = host.get_tree()
	if tree == null:
		return {}
	for node in tree.get_nodes_in_group("water_fountain"):
		if node.has_method("pack_state"):
			return node.call("pack_state")
	return {}


func play_fountain_charge() -> void:
	var tree: SceneTree = host.get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("water_fountain"):
		if node.has_method("begin_charge"):
			node.call("begin_charge")


func play_fountain_splash() -> void:
	var tree: SceneTree = host.get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("water_fountain"):
		if node.has_method("fire_splash"):
			node.call("fire_splash")


static func cells_from_payload(raw: Variant) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if not (raw is Array):
		return cells
	for item in raw:
		cells.append(DungeonGrid.cell_from(item))
	return cells


func _print_region_dump(layout_data: DungeonLayoutData) -> void:
	var room_set: Dictionary = {}
	for region in layout_data.room_regions:
		for point in region.get("cells", []):
			room_set[DungeonGrid.cell_from(point)] = true
	var hall_set: Dictionary = {}
	for cell in layout_data.walkable_cells:
		if not room_set.has(cell):
			hall_set[cell] = true
	var spawn_counts: Dictionary = {}
	for spawn in layout_data.monster_spawns:
		var spawn_cell: Vector2i = DungeonGrid.cell_from(spawn.get("position", {}))
		spawn_counts[spawn_cell] = int(spawn_counts.get(spawn_cell, 0)) + 1
	for region in layout_data.room_regions:
		var doors: int = 0
		var spawns: int = 0
		var cells: Array = region.get("cells", [])
		for point in cells:
			var cell: Vector2i = DungeonGrid.cell_from(point)
			var is_door: bool = false
			for neighbor in DungeonGrid.neighbors(cell):
				if hall_set.has(neighbor):
					is_door = true
					break
			if is_door:
				doors += 1
			spawns += int(spawn_counts.get(cell, 0))
		print(
			"[dungeon] role=%s id=%s cells=%d doors=%d spawns=%d" % [
				str(region.get("role", "")),
				str(region.get("roomId", "")),
				cells.size(),
				doors,
				spawns
			]
		)


func _smoke_check_generated_tiles(layout_data: DungeonLayoutData) -> void:
	var tree: SceneTree = host.get_tree()
	if tree == null:
		return
	var walkable_set: Dictionary = DungeonGrid.set_from(layout_data.walkable_cells)
	var tiles: Array = tree.get_nodes_in_group("generated_dungeon_tiles")
	var off_grid: int = 0
	var ew_ok: int = 0
	var ew_bad: int = 0
	for tile in tiles:
		if not (tile is Node2D):
			continue
		var node: Node2D = tile
		var px: int = int(round(node.position.x))
		var py: int = int(round(node.position.y))
		var cell_px: int = int(DungeonGrid.CELL_PX)
		if px % cell_px != 0 or py % cell_px != 0:
			off_grid += 1
		if "wall_type" in node:
			var cell: Vector2i = Vector2i(int(round(node.position.x / DungeonGrid.CELL_PX)), int(round(node.position.y / DungeonGrid.CELL_PX)))
			var is_ew: bool = walkable_set.has(cell + Vector2i.RIGHT) or walkable_set.has(cell + Vector2i.LEFT)
			if is_ew:
				if int(node.wall_type) == 2:
					ew_ok += 1
				else:
					ew_bad += 1
	print(
		"[dungeon] tile smoke tiles=%d off_grid=%d ew_type2=%d ew_bad=%d" % [
			tiles.size(),
			off_grid,
			ew_ok,
			ew_bad
		]
	)
	if off_grid > 0 or ew_bad > 0:
		push_warning("DungeonGenerationManager: tile smoke failed off_grid=%d ew_bad=%d" % [off_grid, ew_bad])
