class_name RealityTileDrift extends Node

## Host-only: stagger Reality-claimed outside tiles onto Reality art.
## Dungeon floors/walls are never eligible. Grass stays grass, dirt stays dirt.

const DEFAULT_DELAY_MIN := 0.5
const DEFAULT_DELAY_MAX := 8.0
const MAX_CONVERTS_PER_FRAME := 1

var delay_min: float = DEFAULT_DELAY_MIN
var delay_max: float = DEFAULT_DELAY_MAX

var _pending: Dictionary = {}
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	if not SignalBus.reality_claim_changed.is_connected(_on_claim_changed):
		SignalBus.reality_claim_changed.connect(_on_claim_changed)

func _physics_process(_delta: float) -> void:
	if not _is_host():
		return
	_sync_schedules()
	_fire_due()

func _is_host() -> bool:
	if multiplayer.multiplayer_peer == null:
		return true
	return multiplayer.is_server()

func clear_schedules() -> void:
	_pending.clear()

func _on_claim_changed(_unused = null) -> void:
	if not _is_host():
		return
	_sync_schedules()

func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0

func _sync_schedules() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var seen: Dictionary = {}
	for node in tree.get_nodes_in_group("outside_tiles"):
		if not (node is OutsideTile) or not is_instance_valid(node):
			continue
		var tile: OutsideTile = node
		var cell: Vector2i = DungeonGrid.from_world(tile.position)
		seen[cell] = true
		if not is_reality_drift_eligible(cell):
			_pending.erase(cell)
			continue
		if tile.element_presentation == OutsideTile.ElementPresentation.REALITY:
			_pending.erase(cell)
			continue
		if _pending.has(cell):
			continue
		var delay: float = _rng.randf_range(delay_min, maxf(delay_min, delay_max))
		_pending[cell] = _now() + delay
	var stale: Array = []
	for cell in _pending.keys():
		if not seen.has(cell):
			stale.append(cell)
	for cell in stale:
		_pending.erase(cell)

func is_reality_drift_eligible(cell: Vector2i) -> bool:
	var center: Vector2 = DungeonGrid.to_world_center(cell)
	if _is_dungeon_center(center, cell):
		return false
	var tile: OutsideTile = _tile_at(cell)
	if tile == null:
		return false
	return RealityClaim.is_world_claimed(get_tree(), center)

func _is_dungeon_center(_center: Vector2, cell: Vector2i) -> bool:
	var level: Node = _level()
	if level and level.has_method("dungeon_cell_bounds"):
		var dungeon: Rect2i = level.dungeon_cell_bounds()
		if dungeon.size.x > 0 and dungeon.size.y > 0:
			return dungeon.has_point(cell)
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager and manager.has_method("get_dungeon_cell_bounds"):
		var dgm: Rect2i = manager.get_dungeon_cell_bounds()
		if dgm.size.x > 0 and dgm.size.y > 0:
			return dgm.has_point(cell)
	return false

func _fire_due() -> void:
	var now: float = _now()
	var due: Array[Vector2i] = []
	for cell in _pending.keys():
		if float(_pending[cell]) <= now:
			due.append(cell)
	due.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	)
	var converted := 0
	for cell in due:
		if converted >= MAX_CONVERTS_PER_FRAME:
			break
		_pending.erase(cell)
		if _convert_cell(cell):
			converted += 1

func _convert_cell(cell: Vector2i) -> bool:
	var tile: OutsideTile = _tile_at(cell)
	if tile == null:
		return false
	if not is_reality_drift_eligible(cell):
		return false
	if tile.element_presentation == OutsideTile.ElementPresentation.REALITY:
		return false
	if not tile.has_presentation_strip(OutsideTile.ElementPresentation.REALITY):
		push_error("US-002: missing Reality strip for kind %s variety %s; leaving current presentation" % [tile.ground_kind, tile.variety])
		return false
	var kind: int = int(tile.ground_kind)
	var variety: int = int(tile.variety)
	tile.element_presentation = OutsideTile.ElementPresentation.REALITY
	if int(tile.ground_kind) != kind or int(tile.variety) != variety:
		tile.ground_kind = kind
		tile.variety = variety
	_broadcast_presentation(cell, int(OutsideTile.ElementPresentation.REALITY))
	return true

func _broadcast_presentation(cell: Vector2i, presentation: int) -> void:
	var level: Node = _level()
	if level and level.has_method("broadcast_outside_presentation"):
		level.broadcast_outside_presentation(cell, presentation)

func _tile_at(cell: Vector2i) -> OutsideTile:
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("outside_tiles"):
		if not (node is OutsideTile) or not is_instance_valid(node):
			continue
		if DungeonGrid.from_world((node as OutsideTile).position) == cell:
			return node as OutsideTile
	return null

func _level() -> Node:
	return get_parent()
