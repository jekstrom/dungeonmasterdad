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
@export var item_pickups: Array[Dictionary] = []
@export var fountain_cell: Vector2i = DungeonGrid.SENTINEL
@export var fountain_room_cells: Array[Vector2i] = []
@export var generation_seed: int = 100

func translate_cells(delta: Vector2i) -> void:
	if delta == Vector2i.ZERO:
		return
	entrance_cell += delta
	exit_cell += delta
	if fountain_cell != DungeonGrid.SENTINEL:
		fountain_cell += delta
	fountain_room_cells = _shifted_vector_cells(fountain_room_cells, delta)
	walkable_cells = _shifted_vector_cells(walkable_cells, delta)
	blocked_cells = _shifted_vector_cells(blocked_cells, delta)
	main_path_cells = _shifted_vector_cells(main_path_cells, delta)
	_shift_region_cells(room_regions, delta)
	_shift_region_cells(hallway_regions, delta)
	_shift_point_dicts(tile_placements, delta)
	_shift_point_dicts(monster_spawns, delta)
	_shift_point_dicts(item_pickups, delta)

func _shifted_vector_cells(cells: Array[Vector2i], delta: Vector2i) -> Array[Vector2i]:
	var shifted: Array[Vector2i] = []
	for cell in cells:
		shifted.append(cell + delta)
	return shifted

func _shift_region_cells(regions: Array[Dictionary], delta: Vector2i) -> void:
	for region in regions:
		var raw: Variant = region.get("cells", [])
		if not raw is Array:
			continue
		var shifted: Array = []
		for point in raw:
			var cell: Vector2i = DungeonGrid.cell_from(point) + delta
			if point is Vector2i:
				shifted.append(cell)
			else:
				shifted.append({"x": cell.x, "y": cell.y})
		region["cells"] = shifted

func _shift_point_dicts(items: Array[Dictionary], delta: Vector2i) -> void:
	for item in items:
		var point: Variant = item.get("position", {})
		var cell: Vector2i = DungeonGrid.cell_from(point) + delta
		item["position"] = {"x": cell.x, "y": cell.y}

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
		"monsterSpawns": monster_spawns,
		"itemPickups": item_pickups,
		"fountain": _fountain_contract()
	}


func _fountain_contract() -> Dictionary:
	if fountain_cell == DungeonGrid.SENTINEL:
		return {}
	return {
		"x": fountain_cell.x,
		"y": fountain_cell.y,
		"cells": DungeonGrid.points_to_dicts(fountain_room_cells)
	}
