class_name RealityClaim extends RefCounted

## Host-side Reality coverage: west-anchored home ∪ live pockets.
## Circles are never the occupancy source. Newer pockets win overlay overlap.

var home_rect: Rect2i = Rect2i()
var pockets: Array[Dictionary] = []

var _next_id: int = 1
var _next_seq: int = 1

func is_claimed_cell(cell: Vector2i) -> bool:
	if winning_pocket_id(cell) >= 0:
		return true
	return _home_covers(cell)

func is_claimed_world(world: Vector2) -> bool:
	return is_claimed_cell(DungeonGrid.from_world(world))

func overlay_kind_for_cell(cell: Vector2i) -> String:
	if winning_pocket_id(cell) >= 0:
		return "pocket"
	if _home_covers(cell):
		return "home"
	return ""

func winning_pocket_id(cell: Vector2i) -> int:
	var best_seq: int = -1
	var best_id: int = -1
	for pocket in pockets:
		var rect: Rect2i = pocket["rect"]
		if rect.size.x <= 0 or rect.size.y <= 0:
			continue
		if not rect.has_point(cell):
			continue
		var seq: int = int(pocket["seq"])
		if seq >= best_seq:
			best_seq = seq
			best_id = int(pocket["id"])
	return best_id

func add_pocket(rect: Rect2i, duration: float, now: float) -> Dictionary:
	if rect.size.x <= 0 or rect.size.y <= 0:
		return {}
	if duration <= 0.0:
		return {}
	var pocket := {
		"id": _next_id,
		"rect": rect,
		"duration": duration,
		"expires_at": now + duration,
		"seq": _next_seq,
	}
	_next_id += 1
	_next_seq += 1
	pockets.append(pocket)
	return pocket

func expire_pocket(pocket_id: int) -> bool:
	for i in range(pockets.size()):
		if int(pockets[i]["id"]) == pocket_id:
			pockets.remove_at(i)
			return true
	return false

func expire_due(now: float) -> PackedInt32Array:
	var expired: PackedInt32Array = PackedInt32Array()
	var remaining: Array[Dictionary] = []
	for pocket in pockets:
		if float(pocket["expires_at"]) <= now:
			expired.append(int(pocket["id"]))
		else:
			remaining.append(pocket)
	pockets = remaining
	return expired

func clear_pockets() -> void:
	pockets.clear()

func live_pocket_count() -> int:
	return pockets.size()

func pocket_cells() -> Array[Vector2i]:
	var seen: Dictionary = {}
	var cells: Array[Vector2i] = []
	for pocket in pockets:
		var rect: Rect2i = pocket["rect"]
		if rect.size.x <= 0 or rect.size.y <= 0:
			continue
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				var cell := Vector2i(x, y)
				if seen.has(cell):
					continue
				seen[cell] = true
				cells.append(cell)
	return cells

func _home_covers(cell: Vector2i) -> bool:
	return home_rect.size.x > 0 and home_rect.size.y > 0 and home_rect.has_point(cell)
