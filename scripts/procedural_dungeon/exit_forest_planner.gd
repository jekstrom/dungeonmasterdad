class_name ExitForestPlanner extends RefCounted
## US-032: pocket / egress / skill-tree cell plan for dense exit forest.
## Pocket = interior outside cells near the overworld landing beyond the live exit.
## Egress = exit door/room cell + clear outside landing (kept free of trunks).
##
## Exit room centers sit several cells inside the dungeon AABB (room radius + wall
## shell). Adjacent-only landing fails there — we project along preferred dirs
## (west first for east-flush) until an eligible outside cell is found.

const DEFAULT_POCKET_RADIUS := 2
const DEFAULT_DENSITY := 0.85
## How far to walk from exit_cell when no adjacent outside landing exists.
## Covers room radius 2 + wall shell 1 with margin for larger rooms.
const MAX_LANDING_PROJECT_STEPS := 8
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
	var approach: Array[Vector2i] = []
	if landing == DungeonGrid.SENTINEL:
		var projected: Dictionary = _project_landing(
			map_bounds, dungeon, exit_cell, west, building_blocked
		)
		landing = projected.get("landing", DungeonGrid.SENTINEL)
		for cell in projected.get("approach", []):
			approach.append(cell)

	var egress: Array[Vector2i] = []
	var egress_set: Dictionary = {}
	_add_unique(egress, egress_set, exit_cell)
	if landing != DungeonGrid.SENTINEL:
		_add_unique(egress, egress_set, landing)
	# Keep the outside approach corridor clear so the DM can step out.
	for cell in approach:
		if _is_eligible_outside(map_bounds, dungeon, cell, west, building_blocked):
			_add_unique(egress, egress_set, cell)

	var radius: int = maxi(pocket_radius, 1)
	# Anchor on landing (overworld) and exit (harness / edge-flush cases).
	var anchors: Array[Vector2i] = []
	if landing != DungeonGrid.SENTINEL:
		anchors.append(landing)
	anchors.append(exit_cell)

	var pocket: Array[Vector2i] = []
	var pocket_set: Dictionary = {}
	for anchor in anchors:
		for y in range(anchor.y - radius, anchor.y + radius + 1):
			for x in range(anchor.x - radius, anchor.x + radius + 1):
				var cell := Vector2i(x, y)
				if DungeonGrid.chebyshev(cell, anchor) > radius:
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
	## Prefer placeable cell nearest the live exit/landing (Chebyshev, same as pocket).
	## Prefer cells that can keep an empty 8-neigh ring (no forest trunks on Chebyshev-1).
	## Fallback: nearest that can clear the ring, then any placeable.
	var placeable: Array = plan_data.get("placeable", [])
	if placeable.is_empty():
		return DungeonGrid.SENTINEL
	var landing: Vector2i = plan_data.get("landing", DungeonGrid.SENTINEL)
	var exit_cell: Vector2i = plan_data.get("exit_cell", DungeonGrid.SENTINEL)
	var anchor: Vector2i = landing if landing != DungeonGrid.SENTINEL else exit_cell
	var place_set: Dictionary = {}
	for cell in placeable:
		place_set[cell] = true
	# Tier 1: cells that allow a clear 8-neigh ring under adjacency exclusion.
	var clearable: Array[Vector2i] = []
	for cell in placeable:
		if _skill_cell_allows_clear_ring(cell, place_set):
			clearable.append(cell)
	if not clearable.is_empty():
		return _nearest_placeable(clearable, anchor, rng)
	# Tier 2: any placeable (tiny degenerate pockets).
	var any_cells: Array[Vector2i] = []
	for cell in placeable:
		any_cells.append(cell)
	return _nearest_placeable(any_cells, anchor, rng)


func skill_tree_tree_placeable(plan_data: Dictionary, skill_cell: Vector2i) -> Array[Vector2i]:
	## Placeable leftover after Skill Tree + its Chebyshev-1 (8-neigh) exclusion.
	var out: Array[Vector2i] = []
	for cell in plan_data.get("placeable", []):
		if skill_cell != DungeonGrid.SENTINEL and DungeonGrid.chebyshev(cell, skill_cell) <= 1:
			continue
		out.append(cell)
	return out


func _skill_cell_allows_clear_ring(cell: Vector2i, place_set: Dictionary) -> bool:
	## True when rebuild can leave every placeable Chebyshev-1 neighbor empty.
	## Always achievable via exclusion; kept as an explicit gate for tiny-pocket fallback.
	# Vacuous / achievable: exclusion never forces a neighbor trunk.
	return place_set.has(cell)


func _nearest_placeable(
	candidates: Array[Vector2i],
	anchor: Vector2i,
	rng: RandomNumberGenerator
) -> Vector2i:
	if candidates.is_empty():
		return DungeonGrid.SENTINEL
	if anchor == DungeonGrid.SENTINEL:
		var copy: Array[Vector2i] = candidates.duplicate()
		_shuffle_cells(copy, rng)
		return copy[0]
	var best_dist := 2147483647
	var best: Array[Vector2i] = []
	for cell in candidates:
		var d: int = DungeonGrid.chebyshev(cell, anchor)
		if d < best_dist:
			best_dist = d
			best = [cell]
		elif d == best_dist:
			best.append(cell)
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


func normalize_density(raw: float) -> float:
	## Fill fraction in [0, 1]. Values >1 (e.g. inspector "10") mean max dense.
	if raw > 1.0:
		return 1.0
	return clampf(raw, 0.0, 1.0)


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


func _project_landing(
	map_bounds: MapBounds,
	dungeon: Rect2i,
	exit_cell: Vector2i,
	west: Dictionary,
	building_blocked: Dictionary
) -> Dictionary:
	## Walk each preferred dir from the exit until the first eligible outside cell.
	for dir in PREFERRED_LANDING_DIRS:
		var approach: Array[Vector2i] = []
		var cursor: Vector2i = exit_cell
		for _step in range(MAX_LANDING_PROJECT_STEPS):
			cursor += dir
			if _is_eligible_outside(map_bounds, dungeon, cursor, west, building_blocked):
				return {"landing": cursor, "approach": approach}
			# Still inside dungeon / blocked: keep walking; record nothing yet.
			# Once we leave the dungeon AABB we only accept eligible outside.
			if dungeon.size.x > 0 and dungeon.size.y > 0 and dungeon.has_point(cursor):
				continue
			# Off-map / cliff / west strip between dungeon and open overworld — stop this dir.
			break
	return {"landing": DungeonGrid.SENTINEL, "approach": [] as Array[Vector2i]}


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
