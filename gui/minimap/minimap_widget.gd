extends Control

## US-033 corner mini-map. Fit-to-interior cell grid; paints fog, zone washes,
## building pips, and role-gated player markers. Toggle with M.

const ROLE_PP := 0
const ROLE_DM := 1

const PANEL_SIZE := Vector2(200.0, 200.0)
const FOG_COLOR := Color(0.06, 0.07, 0.09, 0.92)
const REVEALED_BASE := Color(0.22, 0.24, 0.20, 0.95)
const REALITY_WASH := Color(0.25, 0.45, 0.85, 0.55)
const FANTASY_WASH := Color(0.72, 0.28, 0.78, 0.55)
const BUILDING_COLOR := Color(0.85, 0.65, 0.20, 1.0)
const PP_PIP := Color(0.25, 0.95, 0.95, 1.0)
const DM_PIP := Color(0.95, 0.35, 0.20, 1.0)
const FRAME_COLOR := Color(0.12, 0.12, 0.14, 0.95)
const BORDER_COLOR := Color(0.55, 0.55, 0.58, 1.0)

@export var role: int = ROLE_PP

var _visible_map: bool = true


func _ready() -> void:
	custom_minimum_size = PANEL_SIZE
	size = PANEL_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	visible = _visible_map
	_connect_fog_signals()
	if not SignalBus.map_bounds_committed.is_connected(_on_bounds_changed):
		SignalBus.map_bounds_committed.connect(_on_bounds_changed)
	if not SignalBus.map_bounds_cleared.is_connected(_on_bounds_cleared):
		SignalBus.map_bounds_cleared.connect(_on_bounds_cleared)
	set_process(true)
	queue_redraw()


func configure(role_id: int) -> void:
	role = role_id
	_connect_fog_signals()
	queue_redraw()


func is_map_visible() -> bool:
	return _visible_map


func set_map_visible(on: bool) -> void:
	_visible_map = on
	visible = on
	queue_redraw()


func toggle_map() -> void:
	set_map_visible(not _visible_map)


func _connect_fog_signals() -> void:
	var fog: Node = _fog()
	if fog == null:
		return
	if fog.has_signal("pp_reveal_changed") and not fog.pp_reveal_changed.is_connected(_on_reveal_changed):
		fog.pp_reveal_changed.connect(_on_reveal_changed)
	if fog.has_signal("dm_reveal_changed") and not fog.dm_reveal_changed.is_connected(_on_reveal_changed):
		fog.dm_reveal_changed.connect(_on_reveal_changed)


func _fog() -> Node:
	return get_node_or_null("/root/MinimapFog")


func _on_reveal_changed() -> void:
	queue_redraw()


func _on_bounds_changed(_interior: Rect2i = Rect2i()) -> void:
	queue_redraw()


func _on_bounds_cleared() -> void:
	queue_redraw()


func _process(_delta: float) -> void:
	# Marker positions update continuously; cheap redraw for living pips.
	if _visible_map:
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not _owner_hud_active():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.keycode == KEY_M or key.physical_keycode == KEY_M:
			toggle_map()
			var viewport := get_viewport()
			if viewport:
				viewport.set_input_as_handled()


func _owner_hud_active() -> bool:
	var hud := get_parent()
	while hud != null and not (hud is CanvasLayer):
		hud = hud.get_parent()
	if hud is CanvasLayer:
		return (hud as CanvasLayer).visible
	return is_visible_in_tree()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, FRAME_COLOR, true)
	draw_rect(rect, BORDER_COLOR, false, 2.0)

	var interior := _interior_rect()
	if interior.size.x <= 0 or interior.size.y <= 0:
		return

	var cell_w: float = size.x / float(interior.size.x)
	var cell_h: float = size.y / float(interior.size.y)
	var fog: Node = _fog()
	var tree := get_tree()

	for y in range(interior.position.y, interior.end.y):
		for x in range(interior.position.x, interior.end.x):
			var cell := Vector2i(x, y)
			var local := Vector2(
				float(x - interior.position.x) * cell_w,
				float(y - interior.position.y) * cell_h
			)
			var cell_rect := Rect2(local, Vector2(cell_w, cell_h))
			var revealed := false
			if fog != null and fog.has_method("is_cell_revealed"):
				revealed = bool(fog.call("is_cell_revealed", role, cell))
			if not revealed:
				draw_rect(cell_rect, FOG_COLOR, true)
				continue
			draw_rect(cell_rect, REVEALED_BASE, true)
			var claim := ZoneDriftClaim.CLAIM_NONE
			if tree != null:
				claim = ZoneDriftClaim.for_cell(tree, cell)
			if claim == ZoneDriftClaim.CLAIM_REALITY:
				draw_rect(cell_rect, REALITY_WASH, true)
			elif claim == ZoneDriftClaim.CLAIM_FANTASY:
				draw_rect(cell_rect, FANTASY_WASH, true)

	_draw_buildings(interior, cell_w, cell_h, fog)
	_draw_markers(interior, cell_w, cell_h, fog)
	draw_rect(rect, BORDER_COLOR, false, 2.0)


func _draw_buildings(interior: Rect2i, cell_w: float, cell_h: float, fog: Node) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("buildings"):
		if not (node is Node2D):
			continue
		if "is_ghost" in node and bool(node.get("is_ghost")):
			continue
		if "destroyed" in node and bool(node.get("destroyed")):
			continue
		var cell: Vector2i = DungeonGrid.from_world((node as Node2D).global_position)
		if not interior.has_point(cell):
			continue
		var revealed := false
		if fog != null and fog.has_method("is_cell_revealed"):
			revealed = bool(fog.call("is_cell_revealed", role, cell))
		if not revealed:
			continue
		var center := Vector2(
			(float(cell.x - interior.position.x) + 0.5) * cell_w,
			(float(cell.y - interior.position.y) + 0.5) * cell_h
		)
		var pip: float = mini(cell_w, cell_h) * 0.45
		draw_rect(Rect2(center - Vector2(pip, pip) * 0.5, Vector2(pip, pip)), BUILDING_COLOR, true)


func _draw_markers(interior: Rect2i, cell_w: float, cell_h: float, fog: Node) -> void:
	var tree := get_tree()
	if tree == null:
		return
	# Paper Pushers
	for node in tree.get_nodes_in_group("players"):
		if not _marker_actor_alive(node):
			continue
		if not (node is Node2D):
			continue
		var cell: Vector2i = DungeonGrid.from_world((node as Node2D).global_position)
		if not interior.has_point(cell):
			continue
		var show_pp := false
		if role == ROLE_PP:
			show_pp = true # allies always on PP map
		else:
			show_pp = fog != null and fog.has_method("is_cell_revealed") and bool(fog.call("is_cell_revealed", ROLE_DM, cell))
		if show_pp:
			_draw_pip(interior, cell, cell_w, cell_h, PP_PIP)

	# DM
	var dm_node: Node = null
	if DmManager.dm != null and is_instance_valid(DmManager.dm):
		dm_node = DmManager.dm
	else:
		dm_node = tree.get_first_node_in_group("dm")
	if dm_node == null or not _marker_actor_alive(dm_node) or not (dm_node is Node2D):
		return
	var dm_cell: Vector2i = DungeonGrid.from_world((dm_node as Node2D).global_position)
	if not interior.has_point(dm_cell):
		return
	var show_dm := false
	if role == ROLE_DM:
		show_dm = true # self always
	else:
		show_dm = fog != null and fog.has_method("is_cell_revealed") and bool(fog.call("is_cell_revealed", ROLE_PP, dm_cell))
	if show_dm:
		_draw_pip(interior, dm_cell, cell_w, cell_h, DM_PIP)


func _draw_pip(interior: Rect2i, cell: Vector2i, cell_w: float, cell_h: float, color: Color) -> void:
	var center := Vector2(
		(float(cell.x - interior.position.x) + 0.5) * cell_w,
		(float(cell.y - interior.position.y) + 0.5) * cell_h
	)
	var r: float = maxf(2.0, mini(cell_w, cell_h) * 0.35)
	draw_circle(center, r, color)


func _marker_actor_alive(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if node.has_method("is_downed") and bool(node.call("is_downed")):
		return false
	if "hitpoints" in node and int(node.get("hitpoints")) <= 0:
		return false
	return true


func _interior_rect() -> Rect2i:
	var tree := get_tree()
	if tree == null:
		return Rect2i()
	var level: Node = tree.get_first_node_in_group("level_manager")
	if level == null:
		return Rect2i()
	if level.has_method("get_map_bounds"):
		var bounds = level.call("get_map_bounds")
		if bounds != null and bounds.has_method("get_interior"):
			return bounds.get_interior()
	if "map_bounds" in level:
		var mb = level.get("map_bounds")
		if mb != null and mb.has_method("get_interior"):
			return mb.get_interior()
	return Rect2i()
