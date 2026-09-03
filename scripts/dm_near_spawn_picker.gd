class_name DmNearSpawnPicker
extends RefCounted
## US-055: host-only near-DM walkable cell picker (Chebyshev band + soft inland bias).
## Does not instantiate. Fail closed when no eligible cell.

const MIN_CHEBYSHEV: int = 1
const MAX_CHEBYSHEV: int = 3

## Result: { "ok": bool, "cell": Vector2i, "world": Vector2 }
static func pick_near_dm(tree: SceneTree, dm_world: Vector2, rng: RandomNumberGenerator = null) -> Dictionary:
	var empty := {"ok": false, "cell": Vector2i.ZERO, "world": Vector2.ZERO}
	if tree == null:
		return empty
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var dm_cell: Vector2i = DungeonGrid.from_world(dm_world)
	var level: Node = tree.get_first_node_in_group("level_manager")
	var candidates: Array[Vector2i] = _eligible_cells(dm_cell, level)
	if candidates.is_empty():
		return empty
	var chosen: Vector2i = _weighted_inland_pick(candidates, level, rng)
	return {
		"ok": true,
		"cell": chosen,
		"world": DungeonGrid.to_world_center(chosen),
	}


static func _eligible_cells(dm_cell: Vector2i, level: Node) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dy in range(-MAX_CHEBYSHEV, MAX_CHEBYSHEV + 1):
		for dx in range(-MAX_CHEBYSHEV, MAX_CHEBYSHEV + 1):
			var d: int = maxi(absi(dx), absi(dy))
			if d < MIN_CHEBYSHEV or d > MAX_CHEBYSHEV:
				continue
			var cell := dm_cell + Vector2i(dx, dy)
			if not _is_cell_walkable(cell, level):
				continue
			out.append(cell)
	return out


static func _is_cell_walkable(cell: Vector2i, level: Node) -> bool:
	# No map bounds → geometric band only (headless / pre-commit). With bounds, interior-only
	# (cliff/outer walk_rect margins must not count as spawnable floor).
	if level == null or not level.has_method("has_map_bounds") or not level.has_map_bounds():
		return true
	var bounds = level.get_map_bounds()
	if bounds == null:
		return true
	if bounds.has_method("is_interior_cell"):
		return bounds.is_interior_cell(cell)
	var world: Vector2 = DungeonGrid.to_world_center(cell)
	if bounds.has_method("is_world_position_walkable"):
		return bounds.is_world_position_walkable(world)
	return true


static func _inland_score(cell: Vector2i, level: Node) -> float:
	if level == null or not level.has_method("has_map_bounds") or not level.has_map_bounds():
		return 1.0
	var bounds = level.get_map_bounds()
	if bounds == null or not bounds.has_method("get_interior"):
		return 1.0
	var interior: Rect2i = bounds.get_interior()
	if interior.size.x <= 0 or interior.size.y <= 0:
		return 1.0
	# Distance to nearest interior edge (higher = more inland).
	var left: int = cell.x - interior.position.x
	var right: int = (interior.position.x + interior.size.x - 1) - cell.x
	var top: int = cell.y - interior.position.y
	var bottom: int = (interior.position.y + interior.size.y - 1) - cell.y
	var edge: int = mini(mini(left, right), mini(top, bottom))
	return float(maxi(0, edge) + 1)


static func _weighted_inland_pick(cells: Array[Vector2i], level: Node, rng: RandomNumberGenerator) -> Vector2i:
	var weights: Array[float] = []
	var total := 0.0
	for cell in cells:
		# Soft inland bias: weight ∝ inland_score^2 so rim cells are rare but possible.
		var w: float = _inland_score(cell, level)
		w = w * w
		weights.append(w)
		total += w
	if total <= 0.0:
		return cells[rng.randi_range(0, cells.size() - 1)]
	var roll: float = rng.randf() * total
	var acc := 0.0
	for i in range(cells.size()):
		acc += weights[i]
		if roll <= acc:
			return cells[i]
	return cells[cells.size() - 1]


## Resolve DM world anchor for summons (host). Null DM → Vector2.ZERO for headless cast tests.
static func dm_anchor_world() -> Vector2:
	if DmManager.dm != null and is_instance_valid(DmManager.dm):
		return (DmManager.dm as Node2D).global_position
	return Vector2.ZERO
