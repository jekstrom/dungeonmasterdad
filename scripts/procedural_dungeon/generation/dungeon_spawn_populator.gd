extends RefCounted

var _monster_spawn_planner: MonsterSpawnPlanner = MonsterSpawnPlanner.new()
var _pickup_spawn_planner: PickupSpawnPlanner = PickupSpawnPlanner.new()
var _fountain_spawn_planner: FountainSpawnPlanner = FountainSpawnPlanner.new()


func populate(layout_data: DungeonLayoutData, request: DungeonGenerationRequest) -> Dictionary:
	layout_data.monster_spawns = _monster_spawn_planner.plan_spawns(
		layout_data.layout_id,
		layout_data.room_regions,
		layout_data.hallway_regions,
		layout_data.entrance_cell,
		layout_data.exit_cell,
		layout_data.generation_seed,
		request.skip_boss
	)
	layout_data.item_pickups = _pickup_spawn_planner.plan_dungeon_pickups(
		layout_data.room_regions,
		layout_data.hallway_regions,
		layout_data.walkable_cells,
		layout_data.entrance_cell,
		layout_data.exit_cell,
		layout_data.generation_seed,
		layout_data.monster_spawns,
		request.pickup_counts()
	)
	layout_data.fountain_cell = _fountain_spawn_planner.plan_fountain_cell(
		layout_data.room_regions,
		layout_data.walkable_cells,
		layout_data.entrance_cell,
		layout_data.exit_cell,
		layout_data.generation_seed,
		layout_data.monster_spawns,
		layout_data.item_pickups,
		request.skip_fountain
	)
	if layout_data.fountain_cell != DungeonGrid.SENTINEL:
		layout_data.fountain_room_cells = _fountain_spawn_planner.room_cells_containing(
			layout_data.room_regions,
			layout_data.fountain_cell
		)
	else:
		layout_data.fountain_room_cells = []
	return {"ok": true, "layout": layout_data}


func fountain_room_cells(layout_data: DungeonLayoutData) -> Array[Vector2i]:
	return _fountain_spawn_planner.room_cells_containing(
		layout_data.room_regions,
		layout_data.fountain_cell
	)


func validate_populated(layout_data: DungeonLayoutData) -> Dictionary:
	if layout_data.hallway_regions.is_empty():
		return DungeonGenerationTypes.error_payload(
			layout_data.request_id,
			DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE,
			"Layout missing room or hallway regions"
		)
	var found: Dictionary = {}
	for region in layout_data.room_regions:
		found[str(region.get("role", ""))] = true
	for role in ["start", "mid", "exit"]:
		if not found.has(role):
			return DungeonGenerationTypes.error_payload(
				layout_data.request_id,
				DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE,
				"Layout missing room or hallway regions"
			)
	var spawn_set: DungeonSpawnSet = DungeonSpawnSet.new()
	spawn_set.layout_id = layout_data.layout_id
	spawn_set.spawns = layout_data.monster_spawns
	var spawn_validation: Dictionary = spawn_set.validate(
		layout_data.entrance_cell,
		layout_data.exit_cell,
		layout_data.walkable_cells
	)
	if not spawn_validation.get("ok", false):
		return DungeonGenerationTypes.error_payload(
			layout_data.request_id,
			str(spawn_validation.get("error_code", DungeonGenerationTypes.FAILURE_INVALID_REQUEST)),
			str(spawn_validation.get("message", "Spawn set validation failed"))
		)
	var layout_validation: Dictionary = layout_data.validate()
	if not layout_validation.get("ok", false):
		return DungeonGenerationTypes.error_payload(
			layout_data.request_id,
			str(layout_validation.get("error_code", DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE)),
			str(layout_validation.get("message", "Layout validation failed"))
		)
	return {"ok": true, "layout": layout_data}
