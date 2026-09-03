class_name ZoneDriftClaim extends RefCounted

const CLAIM_NONE := 0
const CLAIM_REALITY := 1
const CLAIM_FANTASY := -1

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
static var _flipped: Array[Vector2i] = []
static var _has_prev_grid: bool = false
static var _snapshot_sig: int = 0
static var _bus_bound: bool = false
static var _listeners: Array[Callable] = []
static var _listener_queued: bool = false


static func for_cell(tree: SceneTree, cell: Vector2i) -> int:
	ensure_snapshot(tree)
	return claim_at(cell)


static func claim_at(cell: Vector2i) -> int:
	var idx: int = _index(cell)
	if idx >= 0 and idx < _grid.size():
		return _decode(_grid[idx])
	return _compute_from_rects(cell)


static func ensure_snapshot(tree: SceneTree) -> void:
	if tree == null:
		return
	_tree = tree
	_bind_bus()
	_refresh_zones(tree)
	var interior: Rect2i = _interior_rect(tree)
	var sig: int = _live_signature(interior)
	if sig == _snapshot_sig and _grid.size() > 0:
		_flipped.clear()
		return
	_rebuild_grid(tree, interior)
	_snapshot_sig = sig


static func flipped_cells() -> Array[Vector2i]:
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


static func invalidate() -> void:
	_snapshot_sig = 0
	_grid = PackedByteArray()
	_flipped.clear()
	_has_prev_grid = false
	_reality = null
	_fantasy = null


static func _schedule_listeners() -> void:
	if _listener_queued:
		return
	_listener_queued = true
	var tree: SceneTree = _tree
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.process_frame.connect(_run_listeners, CONNECT_ONE_SHOT)
	else:
		_run_listeners()


static func _run_listeners() -> void:
	_listener_queued = false
	var tree: SceneTree = _tree
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	ensure_snapshot(tree)
	var batch: Array[Callable] = _listeners.duplicate()
	_listeners.clear()
	for cb in batch:
		if cb.is_valid():
			cb.call()


static func _on_bus_dirty(_a = null, _b = null, _c = null) -> void:
	_snapshot_sig = 0
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


static func _refresh_zones(tree: SceneTree) -> void:
	if not is_instance_valid(_reality) or not _reality.is_inside_tree():
		_reality = tree.get_first_node_in_group("RealityZone")
	if not is_instance_valid(_fantasy) or not _fantasy.is_inside_tree():
		_fantasy = tree.get_first_node_in_group("FantasyZone")
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


static func _rebuild_grid(_tree: SceneTree, interior: Rect2i) -> void:
	var prev: PackedByteArray = _grid
	var prev_origin := _origin
	var prev_size := _size
	var had_prev: bool = _has_prev_grid and prev.size() > 0
	_flipped.clear()
	if interior.size.x <= 0 or interior.size.y <= 0:
		_origin = Vector2i.ZERO
		_size = Vector2i.ZERO
		_grid = PackedByteArray()
		_has_prev_grid = false
		return
	_origin = interior.position
	_size = interior.size
	var n: int = _size.x * _size.y
	_grid = PackedByteArray()
	_grid.resize(n)
	for y in range(_size.y):
		var row: int = y * _size.x
		var cy: int = _origin.y + y
		for x in range(_size.x):
			var cell := Vector2i(_origin.x + x, cy)
			var encoded: int = _encode(_compute_from_rects(cell))
			_grid[row + x] = encoded
			if not had_prev:
				continue
			var old_idx: int = _index_in(cell, prev_origin, prev_size)
			var old_v: int = 0
			if old_idx >= 0 and old_idx < prev.size():
				old_v = int(prev[old_idx])
			if old_v != encoded:
				_flipped.append(cell)
	_has_prev_grid = true


static func _compute_from_rects(cell: Vector2i) -> int:
	if _rect_list_covers(_reality_pockets, cell):
		return CLAIM_REALITY
	if _rect_list_covers(_fantasy_pockets, cell):
		return CLAIM_FANTASY
	var reality_home := _rect_covers(_reality_home, cell)
	var fantasy_home := _rect_covers(_fantasy_home, cell)
	if reality_home and fantasy_home:
		if _reality_level > _fantasy_level:
			return CLAIM_REALITY
		if _fantasy_level > _reality_level:
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
