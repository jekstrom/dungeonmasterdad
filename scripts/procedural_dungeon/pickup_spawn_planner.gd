class_name PickupSpawnPlanner extends RefCounted

const GREEN_DEW_PATH: String = "res://pickups/mtdew.tres"
const START_ROOM_DEW_COUNT: int = 4

func plan_start_room_dew(
	room_regions: Array[Dictionary],
	entrance_cell: Vector2i,
	exit_cell: Vector2i
) -> Array[Dictionary]:
	var pickups: Array[Dictionary] = []
	for cell in _start_room_dew_cells(room_regions, entrance_cell, exit_cell):
		pickups.append({
			"item_type": GREEN_DEW_PATH,
			"position": {"x": cell.x, "y": cell.y}
		})
	return pickups

func _start_room_dew_cells(
	room_regions: Array[Dictionary],
	entrance_cell: Vector2i,
	exit_cell: Vector2i
) -> Array[Vector2i]:
	var start_set: Dictionary = {}
	for region in room_regions:
		if str(region.get("role", "")) != "start":
			continue
		for point in region.get("cells", []):
			start_set[DungeonGrid.cell_from(point)] = true
	var chosen: Array[Vector2i] = []
	var occupied: Dictionary = {
		entrance_cell: true,
		exit_cell: true
	}
	for step in DungeonGrid.cardinals():
		var neighbor: Vector2i = entrance_cell + step
		if start_set.has(neighbor) and not occupied.has(neighbor):
			chosen.append(neighbor)
			occupied[neighbor] = true
			if chosen.size() >= START_ROOM_DEW_COUNT:
				return chosen
	for cell in start_set.keys():
		if occupied.has(cell):
			continue
		chosen.append(cell)
		occupied[cell] = true
		if chosen.size() >= START_ROOM_DEW_COUNT:
			return chosen
	return chosen
