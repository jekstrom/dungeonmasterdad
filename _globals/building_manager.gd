extends Node

func placement_origin(world: Vector2) -> Vector2:
	return world

func can_place(building_id: String, origin: Vector2, player_id: int) -> bool:
	var data: BuildingData = BuildingDatabase.get_building(building_id)
	if data == null:
		return false
	if data.unique_building and _has_enabled_unique(data):
		return false
	if not _can_afford(player_id, data):
		return false
	return is_area_clear(origin, Vector2(data.size))

func _can_afford(player_id: int, data: BuildingData) -> bool:
	if data == null or data.cost_qty <= 0:
		return true
	if multiplayer.is_server():
		return PlayerManager.has_resources(player_id, data.cost_item, data.cost_qty)
	return PlayerManager.carried_count(player_id, data.cost_item) >= data.cost_qty

@rpc("any_peer", "reliable")
func request_placement(building_id: String, pos: Vector2, _check_pos: Vector2):
	if not multiplayer.is_server(): 
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = multiplayer.get_unique_id()
	var data: BuildingData = BuildingDatabase.get_building(building_id)
	if data == null:
		return
	var origin: Vector2 = pos
	if not can_place(building_id, origin, sender_id):
		return
	var building_root = get_tree().get_first_node_in_group("building_root")
	PlayerManager.consume_resources(sender_id, data.cost_item, data.cost_qty)
	if building_root:
		var building = data.scene.instantiate()
		building.position = origin
		building_root.add_child(building, true)
		building.global_position = origin
		building.enable()
	else:
		print("no building root found")
		assert(false, "no building root")

func _has_enabled_unique(data: BuildingData) -> bool:
	if data == null or not data.unique_building:
		return false
	var want := ""
	if data.scene:
		want = data.scene.resource_path
	var root = get_tree().get_first_node_in_group("building_root")
	if root == null:
		return false
	for child in root.get_children():
		if not is_instance_valid(child):
			continue
		if child is Building and ((child as Building).is_ghost or not (child as Building).is_operating()):
			continue
		if want != "" and str(child.scene_file_path) == want:
			return true
		if child is IrsBuilding and want == "" and (child as Building).is_operating():
			return true
		if child.is_in_group("office_max") and want == "" and (child as Building).is_operating():
			return true
	return false

func is_area_clear(pos: Vector2, size: Vector2, _unused_radius = 0, _unused_pos: Vector2 = Vector2.ZERO) -> bool:
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(size.x, size.y)
	
	query.shape = shape
	query.transform = Transform2D(0, pos)
	query.collision_mask = 1 | 16
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var tree := get_tree()
	if tree:
		for node in tree.get_nodes_in_group("players"):
			if node is CollisionObject2D:
				query.exclude.append((node as CollisionObject2D).get_rid())
		for node in tree.get_nodes_in_group("dm"):
			if node is CollisionObject2D:
				query.exclude.append((node as CollisionObject2D).get_rid())
		for group_name in ["RealityZone", "FantasyZone", "claim_zone"]:
			for node in tree.get_nodes_in_group(group_name):
				if node is CollisionObject2D:
					query.exclude.append((node as CollisionObject2D).get_rid())
		for node in tree.get_nodes_in_group("buildings"):
			if node is Building and bool(node.is_ghost) and node is CollisionObject2D:
				query.exclude.append((node as CollisionObject2D).get_rid())
	
	var space_state = get_tree().root.world_2d.direct_space_state
	
	var result = space_state.intersect_shape(query)
	var blocked := false
	for hit in result:
		var collider: Variant = hit.get("collider")
		if collider is Area2D:
			continue
		if collider is Building and bool((collider as Building).is_ghost):
			continue
		blocked = true
		break
	var footprint := Rect2(pos.x - size.x / 2.0, pos.y - size.y / 2.0, size.x, size.y)
	return not blocked and _footprint_inside_reality(footprint) and _footprint_on_outside_tiles(footprint) and not _footprint_intersects_fantasy(footprint)

func _footprint_inside_reality(footprint: Rect2) -> bool:
	var zone = get_tree().get_first_node_in_group("RealityZone")
	if zone == null:
		return false
	if zone.has_method("contains_world_rect"):
		return zone.contains_world_rect(footprint)
	return false

func _footprint_on_outside_tiles(footprint: Rect2) -> bool:
	var level: Node = get_tree().get_first_node_in_group("level_manager")
	if level == null or not level.has_method("is_outside_build_cell"):
		return false
	var cells: Array[Vector2i] = footprint_cells(footprint)
	if cells.is_empty():
		return false
	for cell in cells:
		if not level.is_outside_build_cell(cell):
			return false
	return true

func footprint_cells(footprint: Rect2) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if footprint.size.x <= 0.0 or footprint.size.y <= 0.0:
		return cells
	var start: Vector2i = DungeonGrid.from_world(footprint.position)
	var end: Vector2i = DungeonGrid.from_world(footprint.end - Vector2(0.001, 0.001))
	for y in range(start.y, end.y + 1):
		for x in range(start.x, end.x + 1):
			cells.append(Vector2i(x, y))
	return cells

func _footprint_intersects_fantasy(footprint: Rect2) -> bool:
	var zone: Node = get_tree().get_first_node_in_group("FantasyZone")
	if zone == null or not zone.has_method("is_claimed_cell"):
		return false
	for cell in footprint_cells(footprint):
		if bool(zone.is_claimed_cell(cell)):
			return true
	return false
