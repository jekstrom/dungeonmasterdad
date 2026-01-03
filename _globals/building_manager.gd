extends Node

@rpc("any_peer", "reliable")
func request_placement(building_id: String, pos: Vector2):
	if not multiplayer.is_server(): 
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	var data: BuildingData = BuildingDatabase.get_building(building_id)
	if PlayerManager.has_resources(sender_id, data.cost_item, data.cost_qty) and is_area_clear(pos, data.size):
		PlayerManager.consume_resources(sender_id, data.cost_item, data.cost_qty)
		
		var building_root = get_tree().get_first_node_in_group("building_root")
		if building_root:
			var building = data.scene.instantiate()
			building.position = pos
			building_root.add_child(building, true)
			building.global_position = pos
			building.enable()
		else:
			print("no building root found")

func is_area_clear(pos, size: Vector2) -> bool:
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = RectangleShape2D.new()
	var shape_size = Vector2(size.x - 2, size.y - 2)
	shape.size = shape_size
	
	query.shape = shape
	query.transform = Transform2D(0, pos)
	query.collision_mask = 1
	
	var space_state = get_tree().root.world_2d.direct_space_state
	
	var result = space_state.intersect_shape(query)
	return result.is_empty()
