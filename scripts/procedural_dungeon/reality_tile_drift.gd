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
		if not _is_eligible(tile, cell):
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

func _is_eligible(tile: OutsideTile, cell: Vector2i) -> bool:
	var level: Node = _level()
	if level and level.has_method("is_outside_build_cell"):
		if not bool(level.is_outside_build_cell(cell)):
			return false
	if level and level.has_method("dungeon_cell_bounds"):
		var dungeon: Rect2i = level.dungeon_cell_bounds()
		if dungeon.size.x > 0 and dungeon.size.y > 0 and dungeon.has_point(cell):
			return false
	var center: Vector2 = DungeonGrid.to_world_center(cell)
	return RealityClaim.is_world_claimed(get_tree(), center)

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
	if not _is_eligible(tile, cell):
		return false
	if tile.element_presentation == OutsideTile.ElementPresentation.REALITY:
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
