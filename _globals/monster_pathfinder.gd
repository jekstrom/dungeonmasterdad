extends Node

const OccupancyScript = preload("res://scripts/pathfinding/occupancy_grid.gd")
const MAX_SEARCHES_PER_FRAME: int = 8
const REPATH_INTERVAL_SEC: float = 0.4
const CACHE_TTL_SEC: float = 0.25
const INLAND_WEIGHT: float = 4.0
const AGENT_CLEARANCE_PX: float = 4.0
const SEGMENT_SAMPLE_PX: float = 8.0

var occupancy = OccupancyScript.new()
var astar: AStarGrid2D = AStarGrid2D.new()
var last_result_deferred: bool = false
var last_used_astar: bool = false
var last_used_los: bool = false
var searches_this_frame: int = 0
var searches_last_frame: int = 0

var _cache: Dictionary = {}
var _cache_time: Dictionary = {}
var _occupancy_dirty: bool = true


func _ready() -> void:
	process_priority = -100
	var overlay: Node2D = preload("res://scripts/pathfinding/path_debug_overlay.gd").new()
	overlay.name = "PathDebugOverlay"
	add_child(overlay)
	if not SignalBus.dungeon_generation_succeeded.is_connected(_on_occupancy_dirty):
		SignalBus.dungeon_generation_succeeded.connect(_on_occupancy_dirty)
	if not SignalBus.map_bounds_committed.is_connected(_on_map_committed):
		SignalBus.map_bounds_committed.connect(_on_map_committed)
	if not SignalBus.map_bounds_cleared.is_connected(_on_occupancy_dirty):
		SignalBus.map_bounds_cleared.connect(_on_occupancy_dirty)
	if not SignalBus.occupancy_solids_changed.is_connected(_on_occupancy_dirty):
		SignalBus.occupancy_solids_changed.connect(_on_occupancy_dirty)


func _process(_delta: float) -> void:
	searches_last_frame = searches_this_frame
	searches_this_frame = 0
	if _occupancy_dirty:
		rebuild()


func _on_map_committed(_interior: Rect2i = Rect2i()) -> void:
	mark_dirty()


func _on_occupancy_dirty(_a = null, _b = null, _c = null) -> void:
	mark_dirty()


func mark_dirty() -> void:
	_occupancy_dirty = true
	_cache.clear()
	_cache_time.clear()


func configure_test_map(region: Rect2i, walkable_cells: Array[Vector2i], cliff_cells: Array = []) -> void:
	var cliffs: Array[Vector2i] = []
	for cell in cliff_cells:
		cliffs.append(cell)
	occupancy.load_manual(region, walkable_cells, cliffs)
	_occupancy_dirty = false
	searches_this_frame = 0
	_rebuild_astar()
	_cache.clear()
	_cache_time.clear()


func rebuild() -> void:
	occupancy.rebuild_from_world(get_tree())
	_rebuild_astar()
	_occupancy_dirty = false
	_cache.clear()
	_cache_time.clear()


func is_walkable_cell(cell: Vector2i) -> bool:
	if _occupancy_dirty:
		rebuild()
	if occupancy.region.size.x <= 0:
		return true
	return occupancy.is_walkable(cell)


func is_world_walkable(world: Vector2) -> bool:
	return is_walkable_cell(world_to_cell(world))


func is_dungeon_world(world: Vector2) -> bool:
	if _occupancy_dirty:
		rebuild()
	return occupancy.is_dungeon_path_cell(world_to_cell(world))


func world_to_cell(world: Vector2) -> Vector2i:
	return occupancy.from_world(world)


func cell_center(cell: Vector2i) -> Vector2:
	return occupancy.to_world_center(cell)


func waypoint_world(cell: Vector2i, _along: Vector2 = Vector2.ZERO) -> Vector2:
	return occupancy.to_world_center(cell)


func is_portal_pair(a: Vector2i, b: Vector2i) -> bool:
	return occupancy.is_portal_pair(a, b)


func world_segment_walkable(from_world: Vector2, to_world: Vector2, with_clearance: bool = true) -> bool:
	if occupancy.region.size.x <= 0:
		return true
	if not _line_cells_walkable(from_world, to_world):
		return false
	if not with_clearance:
		return true
	var delta: Vector2 = to_world - from_world
	if delta.length_squared() < 1.0:
		return true
	var perp: Vector2 = delta.normalized().orthogonal() * AGENT_CLEARANCE_PX
	return _line_cells_walkable(from_world + perp, to_world + perp) and _line_cells_walkable(from_world - perp, to_world - perp)


func _line_cells_walkable(from_world: Vector2, to_world: Vector2) -> bool:
	var dist: float = from_world.distance_to(to_world)
	var steps: int = maxi(1, int(ceil(dist / SEGMENT_SAMPLE_PX)))
	var prev: Vector2i = world_to_cell(from_world)
	if not occupancy.is_walkable(prev):
		return false
	for i in range(1, steps + 1):
		var p: Vector2 = from_world.lerp(to_world, float(i) / float(steps))
		var cell: Vector2i = world_to_cell(p)
		if not occupancy.is_walkable(cell):
			return false
		var d: Vector2i = cell - prev
		if absi(d.x) == 1 and absi(d.y) == 1:
			if not occupancy.is_walkable(Vector2i(prev.x + d.x, prev.y)):
				return false
			if not occupancy.is_walkable(Vector2i(prev.x, prev.y + d.y)):
				return false
		prev = cell
	return true


func nearest_walkable_cell(cell: Vector2i) -> Vector2i:
	if _occupancy_dirty:
		rebuild()
	return occupancy.nearest_walkable(cell)


func nearest_walkable_world(world: Vector2) -> Vector2:
	var cell: Vector2i = nearest_walkable_cell(world_to_cell(world))
	if cell == DungeonGrid.SENTINEL:
		return world
	return cell_center(cell)


func flee_world(from_world: Vector2, threat_world: Vector2) -> Vector2:
	var away: Vector2 = from_world - threat_world
	if away.length_squared() < 0.001:
		away = Vector2.RIGHT
	var dest: Vector2 = from_world + away.normalized() * (DungeonGrid.CELL_PX * 4.0)
	return nearest_walkable_world(dest)


func find_path(start_cell: Vector2i, goal_cell: Vector2i, inland: bool = false) -> Array[Vector2i]:
	last_result_deferred = false
	last_used_astar = false
	last_used_los = false
	if _occupancy_dirty:
		rebuild()
	var start: Vector2i = occupancy.nearest_walkable(start_cell)
	var goal: Vector2i = occupancy.nearest_walkable(goal_cell)
	if start == DungeonGrid.SENTINEL or goal == DungeonGrid.SENTINEL:
		return []
	if start == goal:
		return [start]
	if occupancy.is_dungeon_path_cell(start) == occupancy.is_dungeon_path_cell(goal):
		var line: Array[Vector2i] = walkable_line(start, goal)
		if not line.is_empty():
			last_used_los = true
			return line
	var key: String = "%d,%d>%d,%d:%d" % [start.x, start.y, goal.x, goal.y, 1 if inland else 0]
	var now: int = Time.get_ticks_msec()
	if _cache.has(key) and now - int(_cache_time.get(key, 0)) <= int(CACHE_TTL_SEC * 1000.0):
		return _cache[key]
	var path: Array[Vector2i] = _search_astar(start, goal, inland)
	if path.is_empty():
		path = _search_via_portal(start, goal, inland)
	if not path.is_empty():
		_cache[key] = path
		_cache_time[key] = now
	return path


func _portal_ends() -> Array[Vector2i]:
	var ends: Array[Vector2i] = []
	if occupancy.exit_door == DungeonGrid.SENTINEL or occupancy.exit_landing == DungeonGrid.SENTINEL:
		return ends
	var scale: int = occupancy.subdiv()
	var door_origin: Vector2i = occupancy.layout_path_origin(occupancy.exit_door)
	var land_origin: Vector2i = occupancy.layout_path_origin(occupancy.exit_landing)
	for oy in range(scale):
		for ox in range(scale):
			var door_cell: Vector2i = door_origin + Vector2i(ox, oy)
			if not occupancy.is_walkable(door_cell):
				continue
			for ly in range(scale):
				for lx in range(scale):
					var land_cell: Vector2i = land_origin + Vector2i(lx, ly)
					if not occupancy.is_walkable(land_cell):
						continue
					if absi(door_cell.x - land_cell.x) + absi(door_cell.y - land_cell.y) != 1:
						continue
					ends.append(door_cell)
					ends.append(land_cell)
					return ends
	var door_c: Vector2i = occupancy.nearest_walkable(door_origin)
	var land_c: Vector2i = occupancy.nearest_walkable(land_origin)
	if door_c != DungeonGrid.SENTINEL and land_c != DungeonGrid.SENTINEL:
		ends.append(door_c)
		ends.append(land_c)
	return ends


func _search_via_portal(start: Vector2i, goal: Vector2i, inland: bool) -> Array[Vector2i]:
	if occupancy.dungeon_floors.is_empty():
		return []
	if occupancy.is_dungeon_path_cell(start) == occupancy.is_dungeon_path_cell(goal):
		return []
	var ends: Array[Vector2i] = _portal_ends()
	if ends.size() < 2:
		return []
	var start_in: bool = occupancy.is_dungeon_path_cell(start)
	var door_cell: Vector2i = ends[0]
	var land_cell: Vector2i = ends[1]
	var first: Vector2i = door_cell if start_in else land_cell
	var second: Vector2i = land_cell if start_in else door_cell
	var to_first: Array[Vector2i] = _search_astar(start, first, inland)
	if to_first.is_empty():
		return []
	var to_goal: Array[Vector2i] = _search_astar(second, goal, inland)
	if to_goal.is_empty():
		return []
	var path: Array[Vector2i] = []
	for cell in to_first:
		path.append(cell)
	if path[path.size() - 1] != second:
		path.append(second)
	for i in range(to_goal.size()):
		if i == 0 and to_goal[0] == path[path.size() - 1]:
			continue
		path.append(to_goal[i])
	return path


func _search_astar(start: Vector2i, goal: Vector2i, _inland: bool) -> Array[Vector2i]:
	if start == goal:
		return [start]
	if searches_this_frame >= MAX_SEARCHES_PER_FRAME:
		last_result_deferred = true
		return []
	searches_this_frame += 1
	last_used_astar = true
	var raw: PackedVector2Array = astar.get_id_path(start, goal, false)
	var path: Array[Vector2i] = []
	for point in raw:
		var cell := Vector2i(int(point.x), int(point.y))
		if occupancy.is_walkable(cell):
			path.append(cell)
	return path


func walkable_line(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [start]
	var pos: Vector2i = start
	var guard: int = 0
	while pos != goal and guard < 2048:
		guard += 1
		var step: Vector2i = _los_step(pos, goal)
		if step == pos:
			return []
		if not occupancy.is_walkable(step):
			return []
		pos = step
		path.append(pos)
	if pos != goal:
		return []
	return path


func _los_step(pos: Vector2i, goal: Vector2i) -> Vector2i:
	var dx: int = goal.x - pos.x
	var dy: int = goal.y - pos.y
	if dx == 0 and dy == 0:
		return pos
	var h := Vector2i(pos.x + signi(dx), pos.y)
	var v := Vector2i(pos.x, pos.y + signi(dy))
	if dx != 0 and dy != 0:
		var h_ok: bool = occupancy.is_walkable(h)
		var v_ok: bool = occupancy.is_walkable(v)
		if h_ok and (not v_ok or absi(dx) >= absi(dy)):
			return h
		if v_ok:
			return v
		return pos
	if dx != 0:
		return h
	return v


func _rebuild_astar() -> void:
	astar = AStarGrid2D.new()
	astar.cell_size = Vector2.ONE
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	if occupancy.region.size.x <= 0 or occupancy.region.size.y <= 0:
		return
	astar.region = occupancy.region
	astar.update()
	for y in range(occupancy.region.position.y, occupancy.region.end.y):
		for x in range(occupancy.region.position.x, occupancy.region.end.x):
			var cell := Vector2i(x, y)
			if not astar.is_in_boundsv(cell):
				continue
			var walk: bool = occupancy.is_walkable(cell)
			astar.set_point_solid(cell, not walk)
			var weight: float = 1.0
			if walk and occupancy.inland_penalty(cell):
				weight = INLAND_WEIGHT
			astar.set_point_weight_scale(cell, weight)
