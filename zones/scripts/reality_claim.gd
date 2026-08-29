class_name RealityClaim extends RefCounted

## Host-side Reality coverage: west-anchored home ∪ live pockets.
## Circles are never the occupancy source. Newer pockets win overlay overlap.

const SKELETON_SCENE_PATH := "res://monsters/skeleton/skeleton.tscn"

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

static func is_skeleton_scene_path(scene_path: String) -> bool:
	return scene_path == SKELETON_SCENE_PATH or scene_path.ends_with("/skeleton.tscn")

static func zone_from_tree(tree: SceneTree) -> Node:
	if tree == null:
		return null
	return tree.get_first_node_in_group("RealityZone")

static func is_world_claimed(tree: SceneTree, world: Vector2) -> bool:
	var zone: Node = zone_from_tree(tree)
	if zone and zone.has_method("is_claimed_world"):
		return bool(zone.is_claimed_world(world))
	return false

static func should_reject_skeleton_spawn(tree: SceneTree, scene_path: String, world: Vector2) -> bool:
	return is_skeleton_scene_path(scene_path) and is_world_claimed(tree, world)

static func cull_skeletons_in_tree(tree: SceneTree) -> void:
	if tree == null:
		return
	var seen: Dictionary = {}
	for node in tree.get_nodes_in_group("skeletons"):
		seen[node] = true
		_ban_skeleton_if_claimed(node)
	for node in tree.get_nodes_in_group("generated_dungeon_monsters"):
		if seen.has(node):
			continue
		_ban_skeleton_if_claimed(node)

static func _ban_skeleton_if_claimed(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if not (node is Skeleton):
		return
	if node.get("_dying") == true:
		return
	if not (node is Node2D):
		return
	if not is_world_claimed(node.get_tree(), (node as Node2D).global_position):
		return
	if node.has_method("die"):
		node.die()

func to_sync_dict(now: float) -> Dictionary:
	var packed: Array = []
	for pocket in pockets:
		var rect: Rect2i = pocket["rect"]
		var remaining: float = maxf(0.0, float(pocket["expires_at"]) - now)
		packed.append({
			"id": int(pocket["id"]),
			"x": rect.position.x,
			"y": rect.position.y,
			"w": rect.size.x,
			"h": rect.size.y,
			"remaining": remaining,
			"duration": float(pocket["duration"]),
			"seq": int(pocket["seq"]),
		})
	return {
		"home_x": home_rect.position.x,
		"home_y": home_rect.position.y,
		"home_w": home_rect.size.x,
		"home_h": home_rect.size.y,
		"pockets": packed,
		"next_id": _next_id,
		"next_seq": _next_seq,
	}

func apply_sync_dict(payload: Dictionary, now: float) -> void:
	home_rect = Rect2i(
		int(payload.get("home_x", 0)),
		int(payload.get("home_y", 0)),
		int(payload.get("home_w", 0)),
		int(payload.get("home_h", 0))
	)
	pockets.clear()
	for item in payload.get("pockets", []):
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var remaining: float = float(item.get("remaining", 0.0))
		if remaining <= 0.0:
			continue
		var rect := Rect2i(
			int(item.get("x", 0)),
			int(item.get("y", 0)),
			int(item.get("w", 0)),
			int(item.get("h", 0))
		)
		if rect.size.x <= 0 or rect.size.y <= 0:
			continue
		pockets.append({
			"id": int(item.get("id", 0)),
			"rect": rect,
			"duration": float(item.get("duration", remaining)),
			"expires_at": now + remaining,
			"seq": int(item.get("seq", 0)),
		})
	_next_id = int(payload.get("next_id", _next_id))
	_next_seq = int(payload.get("next_seq", _next_seq))

