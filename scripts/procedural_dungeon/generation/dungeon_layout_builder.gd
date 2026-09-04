extends RefCounted

var _entrance_exit_resolver: EntranceExitResolver = EntranceExitResolver.new()
var _room_graph_generator: RoomGraphGenerator = RoomGraphGenerator.new()
var _hallway_carver: HallwayCarver = HallwayCarver.new()
var _maze_infill_generator: MazeInfillGenerator = MazeInfillGenerator.new()
var _layout_composer: LayoutComposer = LayoutComposer.new()
var _path_validator: PathValidator = PathValidator.new()
var _tile_placement_builder: TilePlacementBuilder = TilePlacementBuilder.new()


func build(request: DungeonGenerationRequest, generation_seed: int) -> Dictionary:
	var resolved_points: Dictionary = _entrance_exit_resolver.resolve_positions(
		request.start_position,
		request.exit_position,
		request.generation_bounds
	)
	if not resolved_points.get("ok", false):
		return resolved_points

	var entrance_cell: Vector2i = resolved_points["entrance_cell"]
	var exit_cell: Vector2i = resolved_points["exit_cell"]

	var room_result: Dictionary = _room_graph_generator.generate_room_backbone(
		entrance_cell,
		exit_cell,
		request.generation_bounds,
		generation_seed,
		request.room_radius(),
		request.mid_room_count()
	)
	if not room_result.get("ok", false):
		return DungeonGenerationTypes.error_payload(
			request.request_id,
			str(room_result.get("error_code", DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE)),
			str(room_result.get("message", "Failed to place room backbone"))
		)

	var room_regions: Array[Dictionary] = DungeonGrid.dicts_from(room_result.get("room_regions", []))
	var graph_edges: Array = room_result.get("graph_edges", [])
	var rooms_by_id: Dictionary = rooms_by_id_from(room_regions)

	var hallway_result: Dictionary = _hallway_carver.carve_graph_hallways(
		rooms_by_id,
		graph_edges,
		request.generation_bounds
	)
	var graph_hallway_cells: Array[Vector2i] = DungeonGrid.cells_from(hallway_result.get("hallway_cells", []))

	var infill_result: Dictionary = _maze_infill_generator.generate_infill(
		request.generation_bounds,
		room_regions,
		graph_hallway_cells,
		entrance_cell,
		exit_cell,
		generation_seed
	)
	if not infill_result.get("ok", false):
		return DungeonGenerationTypes.error_payload(
			request.request_id,
			str(infill_result.get("error_code", DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE)),
			str(infill_result.get("message", "Failed to place dead-end pockets"))
		)

	var infill_hallway_cells: Array[Vector2i] = DungeonGrid.cells_from(infill_result.get("hallway_cells", []))
	var deadend_regions: Array[Dictionary] = DungeonGrid.dicts_from(infill_result.get("deadend_regions", []))
	var all_hallway_cells: Array[Vector2i] = []
	all_hallway_cells.append_array(graph_hallway_cells)
	all_hallway_cells.append_array(infill_hallway_cells)

	var composed_layout: Dictionary = _layout_composer.compose(
		room_regions,
		all_hallway_cells,
		deadend_regions
	)

	var walkable_cells: Array[Vector2i] = DungeonGrid.cells_from(composed_layout.get("walkable_cells", []))
	room_regions = DungeonGrid.dicts_from(composed_layout.get("room_regions", []))
	var hallway_regions: Array[Dictionary] = DungeonGrid.dicts_from(composed_layout.get("hallway_regions", []))

	if hallway_regions.is_empty():
		return DungeonGenerationTypes.error_payload(request.request_id, DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE, "Layout missing hallway regions")
	if not roles_present(room_regions, ["start", "mid", "exit"]):
		return DungeonGenerationTypes.error_payload(request.request_id, DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE, "Layout missing required room roles")
	if not rooms_meet_size_and_separation(room_regions, request.center_separation()):
		return DungeonGenerationTypes.error_payload(request.request_id, DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE, "Room size or separation failed")

	var walkable_set: Dictionary = DungeonGrid.set_from(walkable_cells)

	if not _path_validator.has_connected_path(entrance_cell, exit_cell, walkable_cells):
		return DungeonGenerationTypes.error_payload(request.request_id, DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE, "Entrance and exit are not connected")

	var main_path: Array[Vector2i] = _path_validator.build_shortest_path(entrance_cell, exit_cell, walkable_cells)
	var blocked_cells: Array[Vector2i] = DungeonGrid.blocked_cells(request.generation_bounds, walkable_set)

	var layout_data: DungeonLayoutData = DungeonLayoutData.new()
	layout_data.layout_id = "layout_%s_%d" % [request.request_id, Time.get_ticks_msec()]
	layout_data.request_id = request.request_id
	layout_data.grid_size = request.generation_bounds.size
	layout_data.entrance_cell = entrance_cell
	layout_data.exit_cell = exit_cell
	layout_data.walkable_cells = walkable_cells
	layout_data.blocked_cells = blocked_cells
	layout_data.room_regions = room_regions
	layout_data.hallway_regions = hallway_regions
	layout_data.main_path_cells = main_path
	layout_data.generation_seed = generation_seed
	layout_data.tile_placements = _tile_placement_builder.build(layout_data, walkable_set)

	return {
		"ok": true,
		"layout": layout_data
	}


func seed_for(request: DungeonGenerationRequest, attempt_index: int) -> int:
	return request.request_id.hash() + (attempt_index + 1) * 7919


static func rooms_by_id_from(room_regions: Array[Dictionary]) -> Dictionary:
	var rooms: Dictionary = {}
	for region in room_regions:
		var room_id: String = str(region.get("roomId", ""))
		rooms[room_id] = {"center": DungeonGrid.cell_from(region.get("center", {}))}
	return rooms


static func roles_present(room_regions: Array[Dictionary], required: Array) -> bool:
	var found: Dictionary = {}
	for region in room_regions:
		found[str(region.get("role", ""))] = true
	for role in required:
		if not found.has(str(role)):
			return false
	return true


static func rooms_meet_size_and_separation(room_regions: Array[Dictionary], min_separation: int) -> bool:
	var centers: Array[Vector2i] = []
	for region in room_regions:
		var role: String = str(region.get("role", ""))
		var cells: Array = region.get("cells", [])
		if role == "deadend":
			if cells.size() < 5:
				return false
			continue
		if cells.size() < DungeonConstants.MIN_ROOM_CELLS:
			return false
		centers.append(DungeonGrid.cell_from(region.get("center", {})))
	for i in range(centers.size()):
		for j in range(i + 1, centers.size()):
			if DungeonGrid.chebyshev(centers[i], centers[j]) < min_separation:
				return false
	return true
