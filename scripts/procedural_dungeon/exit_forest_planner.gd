class_name ExitForestPlanner extends RefCounted
## US-032: pocket / egress / skill-tree cell plan for dense exit forest.
## Pocket = interior outside cells near the live exit (Chebyshev radius).
## Egress = exit door cell + at least one adjacent outside landing (kept clear).

const DEFAULT_POCKET_RADIUS := 2
const DEFAULT_DENSITY := 0.78
## Prefer overworld face of an east-flush dungeon (west toward Paper Pushers).
const PREFERRED_LANDING_DIRS: Array[Vector2i] = [
	Vector2i.LEFT,
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.RIGHT,
]

func plan(
	map_bounds: MapBounds,
	dungeon: Rect2i,
	exit_cell: Vector2i,
	pocket_radius: int = DEFAULT_POCKET_RADIUS,
	building_blocked: Dictionary = {}
) -> Dictionary:
	var empty := _empty_plan()
	if map_bounds == null or not map_bounds.has_committed_bounds():
		return empty
	if exit_cell == DungeonGrid.SENTINEL:
		return empty

	var west: Dictionary = {}
	for cell in map_bounds.west_spawn_strip_cells(dungeon):
		west[cell] = true

	var landing: Vector2i = _pick_landing(map_bounds, dungeon, exit_cell, west, building_blocked)
	var egress: Array[Vector2i] = []
	var egress_set: Dictionary = {}
	_add_unique(egress, egress_set, exit_cell)
	if landing != DungeonGrid.SENTINEL:
		_add_unique(egress, egress_set, landing)
	else:
		# Degenerate: no outside neighbor — still mark exit so we never plant on the door.
		pass

	var pocket: Array[Vector2i] = []
	var pocket_set: Dictionary = {}
	var radius: int = maxi(pocket_radius, 1)
	for y in range(exit_cell.y - radius, exit_cell.y + radius + 1):
		for x in range(exit_cell.x - radius, exit_cell.x + radius + 1):
			var cell := Vector2i(x, y)
			if DungeonGrid.chebyshev(cell, exit_cell) > radius:
				continue
			if not _is_eligible_outside(map_bounds, dungeon, cell, west, building_blocked):
				continue
			_add_unique(pocket, pocket_set, cell)

	var placeable: Array[Vector2i] = []
	for cell in pocket:
		if egress_set.has(cell):
			continue
		placeable.append(cell)

	return {
		"pocket": pocket,
		"egress": egress,
		"placeable": placeable,
		"landing": landing,
		"exit_cell": exit_cell,
	}


func pick_skill_tree_cell(plan_data: Dictionary, rng: RandomNumberGenerator) -> Vector2i:
	var placeable: Array = plan_data.get("placeable", [])
	if placeable.is_empty():
		return DungeonGrid.SENTINEL
	var pocket_set: Dictionary = {}
	for cell in plan_data.get("pocket", []):
		pocket_set[cell] = true
	var best_score := -1
	var best: Array[Vector2i] = []
	for cell in placeable:
		var neighbors_in_pocket := 0
		for n in DungeonGrid.neighbors(cell):
			if pocket_set.has(n):
				neighbors_in_pocket += 1
		if neighbors_in_pocket > best_score:
			best_score = neighbors_in_pocket
			best = [cell]
		elif neighbors_in_pocket == best_score:
			best.append(cell)
	# Deterministic tie-break among equal surround scores.
	_shuffle_cells(best, rng)
	return best[0]


func _shuffle_cells(cells: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(cells.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Vector2i = cells[i]
		cells[i] = cells[j]
		cells[j] = tmp


func seed_hash(interior: Rect2i, dungeon: Rect2i, exit_cell: Vector2i) -> int:
	return int(hash("exit_forest|%d,%d,%d,%d|%d,%d,%d,%d|%d,%d" % [
		interior.position.x, interior.position.y, interior.size.x, interior.size.y,
		dungeon.position.x, dungeon.position.y, dungeon.size.x, dungeon.size.y,
		exit_cell.x, exit_cell.y
	]))


func _empty_plan() -> Dictionary:
	return {
		"pocket": [] as Array[Vector2i],
		"egress": [] as Array[Vector2i],
		"placeable": [] as Array[Vector2i],
		"landing": DungeonGrid.SENTINEL,
		"exit_cell": DungeonGrid.SENTINEL,
	}


func _pick_landing(
	map_bounds: MapBounds,
	dungeon: Rect2i,
	exit_cell: Vector2i,
	west: Dictionary,
	building_blocked: Dictionary
) -> Vector2i:
	for dir in PREFERRED_LANDING_DIRS:
		var candidate: Vector2i = exit_cell + dir
		if _is_eligible_outside(map_bounds, dungeon, candidate, west, building_blocked):
			return candidate
	return DungeonGrid.SENTINEL


func _is_eligible_outside(
	map_bounds: MapBounds,
	dungeon: Rect2i,
	cell: Vector2i,
	west: Dictionary,
	building_blocked: Dictionary
) -> bool:
	if not map_bounds.is_interior_cell(cell):
		return false
	if map_bounds.is_cliff_cell(cell):
		return false
	if dungeon.size.x > 0 and dungeon.size.y > 0 and dungeon.has_point(cell):
		return false
	if west.has(cell):
		return false
	if building_blocked.has(cell):
		return false
	return true


func _add_unique(list: Array[Vector2i], seen: Dictionary, cell: Vector2i) -> void:
	if seen.has(cell):
		return
	seen[cell] = true
	list.append(cell)

