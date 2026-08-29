extends Node

@rpc("any_peer", "reliable")
func request_placement(building_id: String, pos: Vector2, check_pos: Vector2):
	if not multiplayer.is_server(): 
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	var data: BuildingData = BuildingDatabase.get_building(building_id)
	var building_root = get_tree().get_first_node_in_group("building_root")
	if PlayerManager.has_resources(sender_id, data.cost_item, data.cost_qty) and is_area_clear(check_pos, data.size):
		PlayerManager.consume_resources(sender_id, data.cost_item, data.cost_qty)
		
		if building_root:
			var building = data.scene.instantiate()
			building.position = pos
			building_root.add_child(building, true)
			building.global_position = pos
			building.enable()
		else:
			print("no building root found")
			assert(false, "no building root")

func is_area_clear(pos: Vector2, size: Vector2, _unused_radius = 0, _unused_pos: Vector2 = Vector2.ZERO) -> bool:
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(size.x, size.y)
	
	query.shape = shape
	query.transform = Transform2D(0, pos)
	query.collision_mask = 1
	
	var space_state = get_tree().root.world_2d.direct_space_state
	
	var result = space_state.intersect_shape(query)
	
	var footprint := Rect2(pos.x - size.x / 2.0, pos.y - size.y / 2.0, size.x, size.y)
	return result.is_empty() and _footprint_inside_reality(footprint) and _footprint_on_outside_tiles(footprint)

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
