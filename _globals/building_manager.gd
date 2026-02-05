extends Node

@rpc("any_peer", "reliable")
func request_placement(building_id: String, pos: Vector2, check_pos: Vector2):
	if not multiplayer.is_server(): 
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	var data: BuildingData = BuildingDatabase.get_building(building_id)
	var building_root = get_tree().get_first_node_in_group("building_root")
	var reality_zone_radius = get_tree().get_first_node_in_group("RealityZone").radius
	var reality_zone_pos = get_tree().get_first_node_in_group("RealityZone").global_position
	if PlayerManager.has_resources(sender_id, data.cost_item, data.cost_qty) and is_area_clear(check_pos, data.size, reality_zone_radius, reality_zone_pos):
		PlayerManager.consume_resources(sender_id, data.cost_item, data.cost_qty)
		
		if building_root:
			var building = data.scene.instantiate()
			building.position = pos
			building_root.add_child(building, true)
			building.global_position = pos
			building.enable()
		else:
			print("no building root found")

func is_area_clear(pos: Vector2, size: Vector2, reality_zone_radius: int, reality_zone_pos: Vector2) -> bool:
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(size.x, size.y)
	
	query.shape = shape
	query.transform = Transform2D(0, pos)
	query.collision_mask = 1
	
	var space_state = get_tree().root.world_2d.direct_space_state
	
	var result = space_state.intersect_shape(query)
	
	return result.is_empty() and is_rect_inside_circle(Rect2(pos.x - size.x / 2, pos.y - size.y / 2, size.x, size.y), reality_zone_pos, reality_zone_radius)

func is_rect_inside_circle(rect: Rect2, circle_center: Vector2, radius: float) -> bool:
	var corners = [
		rect.position, # Top-Left
		Vector2(rect.end.x, rect.position.y), # Top-Right
		rect.end, # Bottom-Right
		Vector2(rect.position.x, rect.end.y) # Bottom-Left
	]

	var radius_squared = radius * radius
	
	for corner in corners:
		# If any corner is further than the radius, the rect is NOT completely inside
		if corner.distance_squared_to(circle_center) > radius_squared:
			return false
			
	return true
