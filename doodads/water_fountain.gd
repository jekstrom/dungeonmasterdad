class_name WaterFountain extends Node2D

const CHARGE_SEC := 1.0
const PERIOD_SEC := 8.0
const SPLASH_VFX_SEC := 0.45
const SPLASH_DAMAGE := 6
const KNOCKBACK_PX := 96.0
const FALLBACK_RADIUS_CELLS := 2
const SLICK_SCENE: PackedScene = preload("res://doodads/dew_slick.tscn")

@export var period_sec: float = PERIOD_SEC
@export var charge_sec: float = CHARGE_SEC
@export var slick_duration_sec: float = 6.0

var room_cells: Array[Vector2i] = []
var _home_cell: Vector2i = Vector2i.ZERO
var _timer: float = PERIOD_SEC
var _charging: bool = false
var _splashing: bool = false
var _splash_timer: float = 0.0
var _water_rest: Color = Color(0.12, 0.72, 0.62, 0.92)
var _slick: Node = null

@onready var _water: Polygon2D = $Water
@onready var _charge_glow: Polygon2D = $ChargeGlow
@onready var _splash_wash: Polygon2D = $SplashWash


func _ready() -> void:
	add_to_group("water_fountain")
	y_sort_enabled = true
	_home_cell = DungeonGrid.from_world(global_position)
	if _water:
		_water_rest = _water.color
	_set_charge_visible(false)
	_set_splash_visible(false)
	_rebuild_splash_polygon()
	_timer = period_sec
	if not tree_exiting.is_connected(_on_tree_exiting):
		tree_exiting.connect(_on_tree_exiting)


func configure_room(cell: Vector2i, cells: Array[Vector2i]) -> void:
	_home_cell = cell
	room_cells = cells.duplicate()
	if is_inside_tree():
		_rebuild_splash_polygon()


func is_charging() -> bool:
	return _charging


func is_showing_splash() -> bool:
	return _splashing


func begin_charge() -> void:
	_charging = true
	_splashing = false
	_timer = charge_sec
	_set_splash_visible(false)
	_set_charge_visible(true)


func fire_splash() -> void:
	if not is_inside_tree():
		return
	_charging = false
	_splashing = true
	_splash_timer = SPLASH_VFX_SEC
	_timer = period_sec
	_set_charge_visible(false)
	_set_splash_visible(true)
	_rebuild_splash_polygon()
	_spawn_or_refresh_slick()
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	_apply_splash_hits()


func play_charge_vfx() -> void:
	_charging = true
	_splashing = false
	_set_splash_visible(false)
	_set_charge_visible(true)


func play_splash_vfx() -> void:
	_charging = false
	_splashing = true
	_splash_timer = SPLASH_VFX_SEC
	_set_charge_visible(false)
	_set_splash_visible(true)
	_rebuild_splash_polygon()
	_spawn_or_refresh_slick()


func _process(delta: float) -> void:
	if _splashing:
		_splash_timer -= delta
		if _splash_timer <= 0.0:
			_splashing = false
			_set_splash_visible(false)
	if not multiplayer.has_multiplayer_peer() or not multiplayer.is_server():
		return
	_timer -= delta
	if _charging:
		if _timer > 0.0:
			return
		_broadcast_splash()
		return
	if _timer > 0.0:
		return
	_broadcast_charge()


func _broadcast_charge() -> void:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager and manager.has_method("broadcast_fountain_charge"):
		manager.call("broadcast_fountain_charge")
	else:
		begin_charge()


func _broadcast_splash() -> void:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager and manager.has_method("broadcast_fountain_splash"):
		manager.call("broadcast_fountain_splash")
	else:
		fire_splash()


func _apply_splash_hits() -> void:
	var origin: Vector2 = global_position
	var covered: Dictionary = _covered_cells()
	for actor in _splash_actors():
		if actor == null or not is_instance_valid(actor) or not (actor is Node2D):
			continue
		var body: Node2D = actor as Node2D
		var cell: Vector2i = DungeonGrid.from_world(body.global_position)
		if not covered.has(cell):
			continue
		if body.has_method("apply_fantasy_hit"):
			body.call("apply_fantasy_hit", SPLASH_DAMAGE)
		if body.has_method("apply_knockback"):
			body.call("apply_knockback", origin, KNOCKBACK_PX)


func _splash_actors() -> Array[Node]:
	var actors: Array[Node] = []
	var tree := get_tree()
	if tree == null:
		return actors
	var dm: Node = tree.get_first_node_in_group("dm")
	if dm:
		actors.append(dm)
	if DmManager.dm and is_instance_valid(DmManager.dm) and not actors.has(DmManager.dm):
		actors.append(DmManager.dm)
	for node in tree.get_nodes_in_group("players"):
		actors.append(node)
	return actors


func _covered_cells() -> Dictionary:
	var covered: Dictionary = {}
	if not room_cells.is_empty():
		for cell in room_cells:
			covered[cell] = true
		return covered
	var center: Vector2i = _home_cell
	if center == Vector2i.ZERO:
		center = DungeonGrid.from_world(global_position)
	for y in range(-FALLBACK_RADIUS_CELLS, FALLBACK_RADIUS_CELLS + 1):
		for x in range(-FALLBACK_RADIUS_CELLS, FALLBACK_RADIUS_CELLS + 1):
			covered[center + Vector2i(x, y)] = true
	return covered


func _rebuild_splash_polygon() -> void:
	if _splash_wash == null:
		return
	var rect: Rect2 = _room_world_rect()
	var top_left: Vector2 = to_local(rect.position)
	var size: Vector2 = rect.size
	_splash_wash.polygon = PackedVector2Array([
		top_left,
		top_left + Vector2(size.x, 0.0),
		top_left + size,
		top_left + Vector2(0.0, size.y)
	])


func _room_world_rect() -> Rect2:
	var covered: Dictionary = _covered_cells()
	if covered.is_empty():
		return Rect2(global_position - Vector2(256, 256), Vector2(512, 512))
	var min_c: Vector2i = covered.keys()[0]
	var max_c: Vector2i = min_c
	for cell in covered.keys():
		min_c.x = mini(min_c.x, cell.x)
		min_c.y = mini(min_c.y, cell.y)
		max_c.x = maxi(max_c.x, cell.x)
		max_c.y = maxi(max_c.y, cell.y)
	var pos: Vector2 = DungeonGrid.to_world(min_c)
	var size: Vector2 = DungeonGrid.to_world(max_c + Vector2i.ONE) - pos
	return Rect2(pos, size)


func _set_charge_visible(on: bool) -> void:
	if _charge_glow:
		_charge_glow.visible = on
	if _water:
		_water.color = Color(0.2, 0.95, 0.8, 1.0) if on else _water_rest
		_water.scale = Vector2(1.25, 1.35) if on else Vector2.ONE


func _set_splash_visible(on: bool) -> void:
	if _splash_wash:
		_splash_wash.visible = on


func has_dew_slick() -> bool:
	return _slick != null and is_instance_valid(_slick) and float(_slick.get("remaining_sec")) > 0.0


func slick_remaining() -> float:
	if not has_dew_slick():
		return 0.0
	return float(_slick.get("remaining_sec"))


func pack_state() -> Dictionary:
	var cells: Array[Vector2i] = room_cells.duplicate()
	if cells.is_empty():
		for cell in _covered_cells().keys():
			cells.append(cell)
	var slick_cells: Array = []
	var remaining: float = 0.0
	if has_dew_slick() and _slick.has_method("pack_cells"):
		slick_cells = _slick.call("pack_cells")
		remaining = float(_slick.get("remaining_sec"))
	elif has_dew_slick():
		remaining = float(_slick.get("remaining_sec"))
		for cell in cells:
			slick_cells.append({"x": cell.x, "y": cell.y})
	return {
		"x": _home_cell.x,
		"y": _home_cell.y,
		"cells": DungeonGrid.points_to_dicts(cells),
		"charging": _charging,
		"charge_remaining": _timer if _charging else 0.0,
		"splashing": _splashing,
		"slick_remaining": remaining,
		"slick_cells": slick_cells,
		"ox": global_position.x,
		"oy": global_position.y,
		"slick_duration": slick_duration_sec,
	}


func apply_state(payload: Dictionary) -> void:
	var cell := Vector2i(int(payload.get("x", _home_cell.x)), int(payload.get("y", _home_cell.y)))
	var cells: Array[Vector2i] = []
	var raw_cells: Variant = payload.get("slick_cells", payload.get("cells", []))
	if raw_cells is Array and not (raw_cells as Array).is_empty():
		for item in raw_cells:
			cells.append(DungeonGrid.cell_from(item))
	elif payload.get("cells") is Array:
		for item in payload.get("cells"):
			cells.append(DungeonGrid.cell_from(item))
	configure_room(cell, cells)
	if bool(payload.get("charging", false)):
		begin_charge()
		_timer = maxf(0.0, float(payload.get("charge_remaining", charge_sec)))
	else:
		_charging = false
		_set_charge_visible(false)
	if bool(payload.get("splashing", false)):
		play_splash_vfx()
	var remaining: float = float(payload.get("slick_remaining", 0.0))
	if remaining > 0.0:
		slick_duration_sec = remaining
		_spawn_or_refresh_slick()
		if _slick:
			_slick.set("remaining_sec", remaining)
	elif has_dew_slick():
		_slick.queue_free()
		_slick = null


func _spawn_or_refresh_slick() -> void:
	var cells: Array[Vector2i] = []
	for cell in _covered_cells().keys():
		cells.append(cell)
	if _slick == null or not is_instance_valid(_slick):
		_slick = SLICK_SCENE.instantiate()
		var parent: Node = get_parent()
		if parent == null:
			parent = self
		parent.add_child(_slick)
	if _slick.has_method("refresh"):
		_slick.call("refresh", cells, global_position, slick_duration_sec)


func _on_tree_exiting() -> void:
	_charging = false
	_splashing = false
	_timer = period_sec
	if _slick != null and is_instance_valid(_slick) and _slick.get_parent() == self:
		var keep: Vector2 = _slick.global_position
		var host: Node = get_parent()
		if host:
			_slick.reparent(host)
			_slick.global_position = keep
