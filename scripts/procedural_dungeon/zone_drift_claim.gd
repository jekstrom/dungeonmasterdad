class_name ZoneDriftClaim extends RefCounted

const CLAIM_NONE := 0
const CLAIM_REALITY := 1
const CLAIM_FANTASY := -1
const THREAD_CELL_THRESHOLD := 1024

static var _tree: SceneTree
static var _reality: Node
static var _fantasy: Node
static var _reality_home: Rect2i = Rect2i()
static var _fantasy_home: Rect2i = Rect2i()
static var _reality_pockets: Array[Rect2i] = []
static var _fantasy_pockets: Array[Rect2i] = []
static var _reality_level: int = 0
static var _fantasy_level: int = 0
static var _origin: Vector2i = Vector2i.ZERO
static var _size: Vector2i = Vector2i.ZERO
static var _grid: PackedByteArray = PackedByteArray()
static var _grid_valid: bool = false
static var _flipped: Array[Vector2i] = []
static var _has_prev_grid: bool = false
static var _snapshot_sig: int = 0
static var _bus_bound: bool = false
static var _listeners: Array[Callable] = []
static var _listener_queued: bool = false
static var _work_queued: bool = false
static var _flushing: bool = false
static var _workers: Array[Callable] = []
static var _grid_job_id: int = -1
static var _grid_job_running: bool = false
static var _job_restart: bool = false
static var _job_gen: int = 0
static var _job_origin: Vector2i = Vector2i.ZERO
static var _job_size: Vector2i = Vector2i.ZERO
static var _job_reality_home: Rect2i = Rect2i()
static var _job_fantasy_home: Rect2i = Rect2i()
static var _job_reality_pockets: Array[Rect2i] = []
static var _job_fantasy_pockets: Array[Rect2i] = []
static var _job_reality_level: int = 0
static var _job_fantasy_level: int = 0
static var _job_prev: PackedByteArray = PackedByteArray()
static var _job_prev_origin: Vector2i = Vector2i.ZERO
static var _job_prev_size: Vector2i = Vector2i.ZERO
static var _job_had_prev: bool = false
static var _job_out_grid: PackedByteArray = PackedByteArray()
static var _job_out_flipped: Array[Vector2i] = []
static var _job_out_gen: int = -1


static func for_cell(tree: SceneTree, cell: Vector2i) -> int:
	ensure_snapshot(tree)
	return claim_at(cell)


static func claim_at(cell: Vector2i) -> int:
	if _grid_valid:
		var idx: int = _index(cell)
		if idx >= 0 and idx < _grid.size():
			return _decode(_grid[idx])
	return _compute_from_rects(cell)


static func ensure_snapshot(tree: SceneTree) -> void:
	if tree == null:
		return
	_tree = tree
	_bind_bus()
	_ensure_zone_refs(tree)
	var interior: Rect2i = _interior_rect(tree)
	if _grid_job_running:
		if _snapshot_is_stale(interior):
			_refresh_zones(tree)
			_snapshot_sig = _live_signature(interior)
			_job_restart = true
		return
	if _grid_valid and _snapshot_sig != 0 and not _snapshot_is_stale(interior):
		return
	_refresh_zones(tree)
	_snapshot_sig = _live_signature(interior)
	_start_grid_rebuild(interior)


static func flipped_cells() -> Array[Vector2i]:
	if not _grid_valid:
		return []
	return _flipped.duplicate()


static func coverage_cells(kind: int) -> Array[Vector2i]:
	var seen: Dictionary = {}
	var cells: Array[Vector2i] = []
	var rects: Array[Rect2i] = []
	if kind != CLAIM_FANTASY:
		_append_unique_rect(rects, _reality_home)
		for rect in _reality_pockets:
			_append_unique_rect(rects, rect)
	if kind != CLAIM_REALITY:
		_append_unique_rect(rects, _fantasy_home)
		for rect in _fantasy_pockets:
			_append_unique_rect(rects, rect)
	for rect in rects:
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				var cell := Vector2i(x, y)
				if seen.has(cell):
					continue
				if claim_at(cell) != kind:
					continue
				seen[cell] = true
				cells.append(cell)
	return cells


static func queue_listener(cb: Callable) -> void:
	if cb.is_null() or not cb.is_valid():
		return
	for existing in _listeners:
		if existing == cb:
			_schedule_listeners()
			return
	_listeners.append(cb)
	_schedule_listeners()


static func register_worker(cb: Callable) -> void:
	if cb.is_null() or not cb.is_valid():
		return
	for existing in _workers:
		if existing == cb:
			return
	_workers.append(cb)


static func unregister_worker(cb: Callable) -> void:
	for i in range(_workers.size() - 1, -1, -1):
		if _workers[i] == cb or not _workers[i].is_valid():
			_workers.remove_at(i)


static func is_flushing() -> bool:
	return _flushing


static func is_work_idle() -> bool:
	if _grid_job_running or _work_queued or _listener_queued:
		return false
	if not _listeners.is_empty():
		return false
	return true


static func flush_pending_work() -> void:
	_flushing = true
	var tree: SceneTree = _tree
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	ensure_snapshot(tree)
	_finish_grid_job()
	if _job_restart:
		_job_restart = false
		ensure_snapshot(tree)
		_finish_grid_job()
	_listener_queued = false
	_dispatch_listeners()
	var batch: Array[Callable] = _workers.duplicate()
	for cb in batch:
		if cb.is_valid():
			cb.call()
	_flushing = false


static func invalidate() -> void:
	_snapshot_sig = 0
	_grid = PackedByteArray()
	_grid_valid = false
	_flipped.clear()
	_has_prev_grid = false
	_reality = null
	_fantasy = null
	_job_restart = false
	_job_gen += 1


static func _schedule_listeners() -> void:
	_schedule_work()


static func _schedule_work() -> void:
	if _work_queued:
		return
	_work_queued = true
	_listener_queued = true
	var tree: SceneTree = _tree
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	if tree != null and not _flushing:
		tree.process_frame.connect(_tick_work, CONNECT_ONE_SHOT)
	else:
		_work_queued = false
		_tick_work()


static func _tick_work() -> void:
	_work_queued = false
	var tree: SceneTree = _tree
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	ensure_snapshot(tree)
	if _grid_job_running:
		if not WorkerThreadPool.is_task_completed(_grid_job_id):
			_schedule_work()
			return
		_finish_grid_job()
		if _job_restart:
			_job_restart = false
			ensure_snapshot(tree)
			_schedule_work()
			return
	_listener_queued = false
	_dispatch_listeners()


static func _dispatch_listeners() -> void:
	var batch: Array[Callable] = _listeners.duplicate()
	_listeners.clear()
	for cb in batch:
		if cb.is_valid():
			cb.call()


static func _on_bus_dirty(_a = null, _b = null, _c = null) -> void:
	_snapshot_sig = 0
	_grid_valid = false
	var tree: SceneTree = _tree
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	ensure_snapshot(tree)
	_schedule_listeners()


static func _bind_bus() -> void:
	if _bus_bound:
		return
	_bus_bound = true
	if not SignalBus.reality_claim_changed.is_connected(_on_bus_dirty):
		SignalBus.reality_claim_changed.connect(_on_bus_dirty)
	if not SignalBus.fantasy_claim_changed.is_connected(_on_bus_dirty):
		SignalBus.fantasy_claim_changed.connect(_on_bus_dirty)
	if not SignalBus.reality_home_changed.is_connected(_on_bus_dirty):
		SignalBus.reality_home_changed.connect(_on_bus_dirty)
	if not SignalBus.fantasy_home_changed.is_connected(_on_bus_dirty):
		SignalBus.fantasy_home_changed.connect(_on_bus_dirty)
	if not SignalBus.map_bounds_committed.is_connected(_on_bus_dirty):
		SignalBus.map_bounds_committed.connect(_on_bus_dirty)
	if not SignalBus.map_bounds_cleared.is_connected(_on_cleared):
		SignalBus.map_bounds_cleared.connect(_on_cleared)


static func _on_cleared() -> void:
	invalidate()
	_schedule_listeners()


static func _ensure_zone_refs(tree: SceneTree) -> void:
	if not is_instance_valid(_reality) or not _reality.is_inside_tree():
		_reality = tree.get_first_node_in_group("RealityZone")
	if not is_instance_valid(_fantasy) or not _fantasy.is_inside_tree():
		_fantasy = tree.get_first_node_in_group("FantasyZone")


static func _snapshot_is_stale(interior: Rect2i) -> bool:
	var origin: Vector2i = _job_origin if _grid_job_running else _origin
	var size: Vector2i = _job_size if _grid_job_running else _size
	if interior.position != origin or interior.size != size:
		return true
	if int(PlayerManager.reality_level) != _reality_level:
		return true
	if int(DmManager.fantasy_level) != _fantasy_level:
		return true
	if _zone_home(_reality) != _reality_home:
		return true
	if _zone_home(_fantasy) != _fantasy_home:
		return true
	if _pockets_stale(_reality, _reality_pockets):
		return true
	if _pockets_stale(_fantasy, _fantasy_pockets):
		return true
	return false


static func _pockets_stale(zone: Node, cached: Array[Rect2i]) -> bool:
	if zone == null or not is_instance_valid(zone) or not ("claim" in zone):
		return not cached.is_empty()
	var claim = zone.get("claim")
	if claim == null or not ("pockets" in claim):
		return not cached.is_empty()
	var pockets = claim.pockets
	if pockets.size() != cached.size():
		return true
	for i in range(cached.size()):
		var pocket = pockets[i]
		if typeof(pocket) != TYPE_DICTIONARY:
			return true
		var rect: Rect2i = pocket.get("rect", Rect2i())
		if rect != cached[i]:
			return true
	return false


static func _refresh_zones(_tree: SceneTree) -> void:
	_reality_home = _zone_home(_reality)
	_fantasy_home = _zone_home(_fantasy)
	_reality_pockets = _zone_pockets(_reality)
	_fantasy_pockets = _zone_pockets(_fantasy)
	_reality_level = int(PlayerManager.reality_level)
	_fantasy_level = int(DmManager.fantasy_level)


static func _live_signature(interior: Rect2i) -> int:
	return hash([
		_zone_id(_reality),
		_zone_id(_fantasy),
		_reality_home,
		_fantasy_home,
		_pocket_sig(_reality_pockets),
		_pocket_sig(_fantasy_pockets),
		_reality_level,
		_fantasy_level,
		interior,
	])


static func _start_grid_rebuild(interior: Rect2i) -> void:
	_grid_valid = false
	if interior.size.x <= 0 or interior.size.y <= 0:
		_origin = Vector2i.ZERO
		_size = Vector2i.ZERO
		_grid = PackedByteArray()
		_has_prev_grid = false
		_flipped.clear()
		return
	var n: int = interior.size.x * interior.size.y
	if n <= THREAD_CELL_THRESHOLD or _flushing:
		_rebuild_grid(interior)
		_grid_valid = true
		return
	if _grid_job_running:
		_job_restart = true
		return
	_job_origin = interior.position
	_job_size = interior.size
	_job_reality_home = _reality_home
	_job_fantasy_home = _fantasy_home
	_job_reality_pockets = _reality_pockets.duplicate()
	_job_fantasy_pockets = _fantasy_pockets.duplicate()
	_job_reality_level = _reality_level
	_job_fantasy_level = _fantasy_level
	_job_prev = _grid
	_job_prev_origin = _origin
	_job_prev_size = _size
	_job_had_prev = _has_prev_grid and _grid.size() > 0
	_job_gen += 1
	_grid_job_running = true
	_grid_job_id = WorkerThreadPool.add_task(_thread_rebuild, true)
	_schedule_work()


static func _thread_rebuild() -> void:
	var built: Dictionary = _build_grid_data(
		_job_origin,
		_job_size,
		_job_reality_home,
		_job_fantasy_home,
		_job_reality_pockets,
		_job_fantasy_pockets,
		_job_reality_level,
		_job_fantasy_level,
		_job_prev,
		_job_prev_origin,
		_job_prev_size,
		_job_had_prev
	)
	_job_out_grid = built["grid"]
	_job_out_flipped = built["flipped"]
	_job_out_gen = _job_gen


static func _finish_grid_job() -> void:
	if not _grid_job_running:
		return
	if _grid_job_id >= 0:
		WorkerThreadPool.wait_for_task_completion(_grid_job_id)
	_grid_job_running = false
	_grid_job_id = -1
	if _job_out_gen != _job_gen:
		return
	_apply_grid_job()


static func _apply_grid_job() -> void:
	_origin = _job_origin
	_size = _job_size
	_grid = _job_out_grid
	_flipped = _job_out_flipped
	_has_prev_grid = _size.x > 0 and _size.y > 0
	_grid_valid = _has_prev_grid


static func _rebuild_grid(interior: Rect2i) -> void:
	var built: Dictionary = _build_grid_data(
		interior.position,
		interior.size,
		_reality_home,
		_fantasy_home,
		_reality_pockets,
		_fantasy_pockets,
		_reality_level,
		_fantasy_level,
		_grid,
		_origin,
		_size,
		_has_prev_grid and _grid.size() > 0
	)
	if interior.size.x <= 0 or interior.size.y <= 0:
		_origin = Vector2i.ZERO
		_size = Vector2i.ZERO
		_grid = PackedByteArray()
		_flipped.clear()
		_has_prev_grid = false
		_grid_valid = false
		return
	_origin = interior.position
	_size = interior.size
	_grid = built["grid"]
	_flipped = built["flipped"]
	_has_prev_grid = true
	_grid_valid = true


static func _build_grid_data(
	origin: Vector2i,
	size: Vector2i,
	r_home: Rect2i,
	f_home: Rect2i,
	r_pockets: Array[Rect2i],
	f_pockets: Array[Rect2i],
	r_level: int,
	f_level: int,
	prev: PackedByteArray,
	prev_origin: Vector2i,
	prev_size: Vector2i,
	had_prev: bool
) -> Dictionary:
	var flipped: Array[Vector2i] = []
	var grid := PackedByteArray()
	if size.x <= 0 or size.y <= 0:
		return {"grid": grid, "flipped": flipped}
	var n: int = size.x * size.y
	grid.resize(n)
	for y in range(size.y):
		var row: int = y * size.x
		var cy: int = origin.y + y
		for x in range(size.x):
			var cell := Vector2i(origin.x + x, cy)
			var encoded: int = _encode(_claim_from_packed(cell, r_home, f_home, r_pockets, f_pockets, r_level, f_level))
			grid[row + x] = encoded
			if not had_prev:
				continue
			var old_idx: int = _index_in(cell, prev_origin, prev_size)
			var old_v: int = 0
			if old_idx >= 0 and old_idx < prev.size():
				old_v = int(prev[old_idx])
			if old_v != encoded:
				flipped.append(cell)
	return {"grid": grid, "flipped": flipped}


static func _compute_from_rects(cell: Vector2i) -> int:
	return _claim_from_packed(
		cell,
		_reality_home,
		_fantasy_home,
		_reality_pockets,
		_fantasy_pockets,
		_reality_level,
		_fantasy_level
	)


static func _claim_from_packed(
	cell: Vector2i,
	r_home: Rect2i,
	f_home: Rect2i,
	r_pockets: Array[Rect2i],
	f_pockets: Array[Rect2i],
	r_level: int,
	f_level: int
) -> int:
	if _rect_list_covers(r_pockets, cell):
		return CLAIM_REALITY
	if _rect_list_covers(f_pockets, cell):
		return CLAIM_FANTASY
	var reality_home := _rect_covers(r_home, cell)
	var fantasy_home := _rect_covers(f_home, cell)
	if reality_home and fantasy_home:
		if r_level > f_level:
			return CLAIM_REALITY
		if f_level > r_level:
			return CLAIM_FANTASY
		return CLAIM_NONE
	if reality_home:
		return CLAIM_REALITY
	if fantasy_home:
		return CLAIM_FANTASY
	return CLAIM_NONE


static func _zone_home(zone: Node) -> Rect2i:
	if zone == null or not is_instance_valid(zone):
		return Rect2i()
	if "home_rect" in zone:
		return zone.home_rect
	return Rect2i()


static func _zone_pockets(zone: Node) -> Array[Rect2i]:
	var out: Array[Rect2i] = []
	if zone == null or not is_instance_valid(zone) or not ("claim" in zone):
		return out
	var claim = zone.get("claim")
	if claim == null or not ("pockets" in claim):
		return out
	for pocket in claim.pockets:
		if typeof(pocket) != TYPE_DICTIONARY:
			continue
		var rect: Rect2i = pocket.get("rect", Rect2i())
		if rect.size.x > 0 and rect.size.y > 0:
			out.append(rect)
	return out


static func _zone_id(zone: Node) -> int:
	if zone == null or not is_instance_valid(zone):
		return 0
	return zone.get_instance_id()


static func _pocket_sig(rects: Array[Rect2i]) -> int:
	var bits: Array = []
	for rect in rects:
		bits.append(rect)
	return hash(bits)


static func _rect_covers(rect: Rect2i, cell: Vector2i) -> bool:
	return rect.size.x > 0 and rect.size.y > 0 and rect.has_point(cell)


static func _rect_list_covers(rects: Array[Rect2i], cell: Vector2i) -> bool:
	for rect in rects:
		if _rect_covers(rect, cell):
			return true
	return false


static func _append_unique_rect(rects: Array[Rect2i], rect: Rect2i) -> void:
	if rect.size.x <= 0 or rect.size.y <= 0:
		return
	rects.append(rect)


static func _interior_rect(tree: SceneTree) -> Rect2i:
	if tree == null:
		return Rect2i()
	var level: Node = tree.get_first_node_in_group("level_manager")
	if level == null:
		return Rect2i()
	if "map_bounds" in level:
		var mb = level.get("map_bounds")
		if mb != null and mb.has_method("get_interior"):
			return mb.get_interior()
	if level.has_method("get_map_bounds"):
		var bounds = level.get_map_bounds()
		if bounds != null and bounds.has_method("get_interior"):
			return bounds.get_interior()
	return Rect2i()


static func _index(cell: Vector2i) -> int:
	return _index_in(cell, _origin, _size)


static func _index_in(cell: Vector2i, origin: Vector2i, size: Vector2i) -> int:
	if size.x <= 0 or size.y <= 0:
		return -1
	var x: int = cell.x - origin.x
	var y: int = cell.y - origin.y
	if x < 0 or y < 0 or x >= size.x or y >= size.y:
		return -1
	return y * size.x + x


static func _encode(claim: int) -> int:
	if claim == CLAIM_FANTASY:
		return 2
	if claim == CLAIM_REALITY:
		return 1
	return 0


static func _decode(encoded: int) -> int:
	if encoded == 2:
		return CLAIM_FANTASY
	if encoded == 1:
		return CLAIM_REALITY
	return CLAIM_NONE
