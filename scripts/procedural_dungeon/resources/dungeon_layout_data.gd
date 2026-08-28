class_name DungeonLayoutData extends Resource

@export var layout_id: String = ""
@export var request_id: String = ""
@export var grid_size: Vector2i = Vector2i.ZERO
@export var entrance_cell: Vector2i = Vector2i.ZERO
@export var exit_cell: Vector2i = Vector2i.ZERO
@export var walkable_cells: Array[Vector2i] = []
@export var blocked_cells: Array[Vector2i] = []
@export var room_regions: Array[Dictionary] = []
@export var hallway_regions: Array[Dictionary] = []
@export var main_path_cells: Array[Vector2i] = []
@export var tile_placements: Array[Dictionary] = []
@export var monster_spawns: Array[Dictionary] = []
@export var generation_seed: int = 100

func validate() -> Dictionary:
	if layout_id.strip_edges().is_empty():
		return DungeonGrid.fail("INVALID_REQUEST", "Layout ID is required")

	if entrance_cell == exit_cell:
		return DungeonGrid.fail("START_EQUALS_EXIT", "Entrance and exit cells must be different")

	if walkable_cells.is_empty():
		return DungeonGrid.fail("LAYOUT_INFEASIBLE", "Layout must contain walkable cells")

	if not walkable_cells.has(entrance_cell) or not walkable_cells.has(exit_cell):
		return DungeonGrid.fail("POSITION_NOT_PLACEABLE", "Entrance and exit must be walkable cells")

	if room_regions.is_empty() or hallway_regions.is_empty():
		return DungeonGrid.fail("LAYOUT_INFEASIBLE", "Layout must contain at least one room and one hallway region")

	return {
		"ok": true,
		"error_code": "",
		"message": ""
	}

func to_contract_dictionary() -> Dictionary:
	return {
		"requestId": request_id,
		"layoutId": layout_id,
		"entrance": {"x": entrance_cell.x, "y": entrance_cell.y},
		"exit": {"x": exit_cell.x, "y": exit_cell.y},
		"seed": generation_seed,
		"roomRegions": room_regions,
		"hallwayRegions": hallway_regions,
		"mainPath": DungeonGrid.points_to_dicts(main_path_cells),
		"tilePlacements": tile_placements,
		"monsterSpawns": monster_spawns
	}
