extends Control

## US-033 corner mini-map. Frame chrome + MapView paint (flush to frame hole),
## fog, washes, buildings, living trees, mines, dungeon wall tint, markers.
## Toggle with M (toggle_minimap). DEBUG F10: toggle_minimap_debug_reveal.

const PANEL_SIZE := Vector2(208.0, 208.0)
## Matches frame.png transparent hole (opaque chrome 0..9, hole from 10).
const MAP_INSET := 10.0
const FOG_COLOR := Color(0.06, 0.07, 0.09, 0.92)
const REVEALED_BASE := Color(0.22, 0.24, 0.20, 0.95)
const REALITY_WASH := Color(0.25, 0.45, 0.85, 0.55)
const FANTASY_WASH := Color(0.72, 0.28, 0.78, 0.55)
const BUILDING_COLOR := Color(0.85, 0.65, 0.20, 1.0)
const TREE_COLOR := Color(0.22, 0.72, 0.30, 1.0)
const MINE_COLOR := Color(0.62, 0.58, 0.48, 1.0)
const WALL_TINT := Color(0.14, 0.14, 0.16, 0.95)
const PP_PIP := Color(0.25, 0.95, 0.95, 1.0)
const DM_PIP := Color(0.95, 0.35, 0.20, 1.0)

@export var role_is_dm: bool = false
## v1 default: hide harvested stumps on the mini-map (FR-011 / T010).
@export var show_tree_stumps: bool = false
## Minimum on-screen pip size (px). Player/building/tree/mine/skill-tree pips.
@export var minimap_pip_min_px: float = 8.0

## DEBUG: local paint override only — treat all interior cells as revealed for
## THIS client's paint. Does NOT mutate MinimapReveal host sets; no RPC.
var debug_reveal_all: bool = false
var _debug_reveal_enabled_logged: bool = false

# Harness / callers may use role int (0=PP, 1=DM).
var role: int:
	get:
		return 1 if role_is_dm else 0
	set(v):
		role_is_dm = int(v) == 1

var _visible_map: bool = true
var _tex_fog: Texture2D
var _tex_reality: Texture2D
var _tex_fantasy: Texture2D
var _tex_building: Texture2D
var _tex_tree: Texture2D
var _tex_mine: Texture2D
var _tex_wall: Texture2D
var _tex_pp: Texture2D
var _tex_dm: Texture2D
@onready var _frame: TextureRect = $Frame
@onready var _map_view: Control = $MapView


func _ready() -> void:
	custom_minimum_size = PANEL_SIZE
	size = PANEL_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	visible = _visible_map
	if _frame:
		_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _map_view:
		_map_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Flush MapView to the frame's inner transparent hole (no world ring).
		_map_view.set_anchors_preset(Control.PRESET_FULL_RECT)
		_map_view.offset_left = MAP_INSET
		_map_view.offset_top = MAP_INSET
		_map_view.offset_right = -MAP_INSET
		_map_view.offset_bottom = -MAP_INSET
		if not _map_view.draw.is_connected(_on_map_view_draw):
			# Custom draw via script on MapView — attach draw callback.
			pass
	_load_art_textures()
	_ensure_map_view_drawer()
	_connect_reveal_signals()
	if not SignalBus.map_bounds_committed.is_connected(_on_bounds_changed):
		SignalBus.map_bounds_committed.connect(_on_bounds_changed)
	if not SignalBus.map_bounds_cleared.is_connected(_on_bounds_cleared):
		SignalBus.map_bounds_cleared.connect(_on_bounds_cleared)
	set_process(true)
	# Keep F10 debug reveal reachable even if a parent pauses the tree.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_debug_reveal_action()
	set_process_input(true)
	_request_late_join_if_needed()


func configure(role_or_dm) -> void:
	if typeof(role_or_dm) == TYPE_BOOL:
		role_is_dm = bool(role_or_dm)
	else:
		role_is_dm = int(role_or_dm) == 1
	_connect_reveal_signals()
	_request_late_join_if_needed()
	_queue_map_redraw()


func is_map_visible() -> bool:
	return _visible_map


func set_map_visible(on: bool) -> void:
	_visible_map = on
	visible = on
	_queue_map_redraw()


func toggle_map() -> void:
	set_map_visible(not _visible_map)


func _ensure_debug_reveal_action() -> void:
	## Defensive: editor/export InputMap drift — bind F10 as both keycode + physical.
	const ACTION := "toggle_minimap_debug_reveal"
	if not InputMap.has_action(ACTION):
		InputMap.add_action(ACTION)
	var has_both := false
	for ev in InputMap.action_get_events(ACTION):
		if not (ev is InputEventKey):
			continue
		var key: InputEventKey = ev
		if key.physical_keycode != KEY_F10 and key.keycode != KEY_F10:
			continue
		if key.keycode == KEY_F10 and key.physical_keycode == KEY_F10:
			has_both = true
			break
		InputMap.action_erase_event(ACTION, key)
	if not has_both:
		var bind := InputEventKey.new()
		bind.keycode = KEY_F10
		bind.physical_keycode = KEY_F10
		InputMap.action_add_event(ACTION, bind)


func toggle_debug_reveal() -> void:
	# DEBUG: local paint reveal-all (widget-only; host sets untouched).
	debug_reveal_all = not debug_reveal_all
	print("DEBUG: minimap toggle_minimap_debug_reveal -> debug_reveal_all=%s" % str(debug_reveal_all))
	if debug_reveal_all:
		_debug_reveal_enabled_logged = true
	_queue_map_redraw()


func _hud_layer_active() -> bool:
	# Autoload PlayerHud/DmHud both own a widget; only the visible layer should toggle.
	var p: Node = get_parent()
	while p != null:
		if p is CanvasLayer:
			return (p as CanvasLayer).visible
		p = p.get_parent()
	return is_visible_in_tree()


func _input(event: InputEvent) -> void:
	# Prefer _input over _unhandled_input so focused GUI controls cannot eat F10.
	if get_viewport().is_input_handled():
		return
	if not event.is_action_pressed("toggle_minimap_debug_reveal"):
		return
	if not _hud_layer_active():
		return
	toggle_debug_reveal()
	get_viewport().set_input_as_handled()



func _request_late_join_if_needed() -> void:
	var reveal: Node = _reveal()
	if reveal != null and reveal.has_method("request_snapshot_for_local"):
		reveal.call("request_snapshot_for_local", role_is_dm)


func _load_art_textures() -> void:
	# Preferred Art aliases first (89b3f11); fall back to prefixed minimap_* copies.
	_tex_fog = _load_tex(["res://gui/minimap/fog_wash.png", "res://gui/minimap/minimap_fog_tint.png"])
	_tex_reality = _load_tex(["res://gui/minimap/reality_wash.png", "res://gui/minimap/minimap_reality_wash.png"])
	_tex_fantasy = _load_tex(["res://gui/minimap/fantasy_wash.png", "res://gui/minimap/minimap_fantasy_wash.png"])
	_tex_building = _load_tex([
		"res://gui/minimap/building_pip.png",
		"res://gui/minimap/minimap_building_pip.png",
		"res://gui/minimap/minimap_building_pip_8.png",
	])
	_tex_tree = _load_tex(["res://gui/minimap/tree_pip.png"])
	_tex_mine = _load_tex(["res://gui/minimap/mine_pip.png"])
	_tex_wall = _load_tex(["res://gui/minimap/dungeon_wall_wash.png"])
	_tex_pp = _load_tex([
		"res://gui/minimap/pp_pip.png",
		"res://gui/minimap/minimap_pp_pip.png",
		"res://gui/minimap/minimap_pp_pip_8.png",
	])
	_tex_dm = _load_tex([
		"res://gui/minimap/dm_pip.png",
		"res://gui/minimap/minimap_dm_pip.png",
		"res://gui/minimap/minimap_dm_pip_8.png",
	])


func _load_tex(paths: Array) -> Texture2D:
	for path in paths:
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path) as Texture2D
			if tex != null:
				return tex
	return null


func _ensure_map_view_drawer() -> void:
	if _map_view == null:
		return
	if _map_view.has_method("bind_owner"):
		_map_view.call("bind_owner", self)


func _connect_reveal_signals() -> void:
	var reveal: Node = _reveal()
	if reveal == null:
		return
	if reveal.has_signal("reveal_changed") and not reveal.reveal_changed.is_connected(_on_reveal_changed):
		reveal.reveal_changed.connect(_on_reveal_changed)


func _reveal() -> Node:
	return get_node_or_null("/root/MinimapReveal")


func _on_reveal_changed(_role: String = "") -> void:
	_queue_map_redraw()


func _on_bounds_changed(_interior: Rect2i = Rect2i()) -> void:
	_queue_map_redraw()


func _on_bounds_cleared() -> void:
	_queue_map_redraw()


func _process(_delta: float) -> void:
	if _visible_map:
		_queue_map_redraw()


func _queue_map_redraw() -> void:
	if _map_view:
		_map_view.queue_redraw()


func _on_map_view_draw() -> void:
	pass


## Called by MapView._draw()
func paint_map(ci: Control) -> void:
	var size_v: Vector2 = ci.size
	if size_v.x <= 0.0 or size_v.y <= 0.0:
		return
	var interior := _interior_rect()
	if interior.size.x <= 0 or interior.size.y <= 0:
		return
	# Uniform square cells. When interior is square, fill 100% of the MapView
	# (no letterbox ring). Otherwise width-fit; letterbox top/bottom, clip if taller.
	var cols: float = float(interior.size.x)
	var rows: float = float(interior.size.y)
	var cell_px: float
	if cols == rows:
		cell_px = minf(size_v.x / cols, size_v.y / rows)
	else:
		cell_px = floorf(size_v.x / cols)
	if cell_px <= 0.0:
		return
	var origin := Vector2(
		(size_v.x - cell_px * cols) * 0.5,
		(size_v.y - cell_px * rows) * 0.5
	)
	var reveal: Node = _reveal()
	var tree := get_tree()

	for y in range(interior.position.y, interior.end.y):
		for x in range(interior.position.x, interior.end.x):
			var cell := Vector2i(x, y)
			var local := origin + Vector2(
				float(x - interior.position.x) * cell_px,
				float(y - interior.position.y) * cell_px
			)
			var cell_rect := Rect2(local, Vector2(cell_px, cell_px))
			var revealed := false
			if debug_reveal_all:
				# DEBUG: local paint override — do not touch MinimapReveal sets.
				revealed = true
			elif reveal != null:
				if role_is_dm:
					revealed = bool(reveal.call("is_dm_revealed", cell))
				else:
					revealed = bool(reveal.call("is_pp_revealed", cell))
			if not revealed:
				_paint_fog(ci, cell_rect)
				continue
			ci.draw_rect(cell_rect, REVEALED_BASE, true)
			var claim := ZoneDriftClaim.CLAIM_NONE
			if tree != null:
				claim = ZoneDriftClaim.for_cell(tree, cell)
			if claim == ZoneDriftClaim.CLAIM_REALITY:
				_paint_wash(ci, cell_rect, _tex_reality, REALITY_WASH)
			elif claim == ZoneDriftClaim.CLAIM_FANTASY:
				_paint_wash(ci, cell_rect, _tex_fantasy, FANTASY_WASH)

	_draw_dungeon_walls(ci, interior, cell_px, origin, reveal)
	_draw_buildings(ci, interior, cell_px, origin, reveal)
	_draw_trees(ci, interior, cell_px, origin, reveal)
	_draw_mines(ci, interior, cell_px, origin, reveal)
	_draw_markers(ci, interior, cell_px, origin, reveal)


func _paint_fog(ci: Control, cell_rect: Rect2) -> void:
	if _tex_fog != null:
		ci.draw_texture_rect(_tex_fog, cell_rect, false)
	else:
		ci.draw_rect(cell_rect, FOG_COLOR, true)


func _paint_wash(ci: Control, cell_rect: Rect2, tex: Texture2D, fallback: Color) -> void:
	if tex != null:
		ci.draw_texture_rect(tex, cell_rect, false, Color(1, 1, 1, 0.7))
	else:
		ci.draw_rect(cell_rect, fallback, true)


func _cell_revealed(reveal: Node, cell: Vector2i) -> bool:
	if debug_reveal_all:
		# DEBUG: local paint override only.
		return true
	if reveal == null:
		return false
	if role_is_dm:
		return bool(reveal.call("is_dm_revealed", cell))
	return bool(reveal.call("is_pp_revealed", cell))


func _draw_dungeon_walls(ci: Control, interior: Rect2i, cell_px: float, origin: Vector2, reveal: Node) -> void:
	for cell in collect_revealed_wall_cells(reveal, interior):
		var local := origin + Vector2(
			float(cell.x - interior.position.x) * cell_px,
			float(cell.y - interior.position.y) * cell_px
		)
		var cell_rect := Rect2(local, Vector2(cell_px, cell_px))
		_paint_wash(ci, cell_rect, _tex_wall, WALL_TINT)


func _draw_trees(ci: Control, interior: Rect2i, cell_px: float, origin: Vector2, reveal: Node) -> void:
	for cell in collect_revealed_tree_cells(reveal, interior):
		var center := origin + Vector2(
			(float(cell.x - interior.position.x) + 0.5) * cell_px,
			(float(cell.y - interior.position.y) + 0.5) * cell_px
		)
		_draw_pip_tex(ci, center, cell_px, _tex_tree, TREE_COLOR)


func _draw_mines(ci: Control, interior: Rect2i, cell_px: float, origin: Vector2, reveal: Node) -> void:
	for cell in collect_revealed_mine_cells(reveal, interior):
		var center := origin + Vector2(
			(float(cell.x - interior.position.x) + 0.5) * cell_px,
			(float(cell.y - interior.position.y) + 0.5) * cell_px
		)
		_draw_pip_tex(ci, center, cell_px, _tex_mine, MINE_COLOR)


## Harness / debug: living scattered + exit-forest (+ skill) trees on revealed cells (stumps off by default).
func collect_revealed_tree_cells(reveal: Node, interior: Rect2i = Rect2i()) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var tree := get_tree()
	if tree == null:
		return out
	if interior == Rect2i():
		interior = _interior_rect()
	var seen: Dictionary = {}
	for group_name in ["scattered_trees", "exit_forest_trees", "skill_trees", "exit_forest_skill_trees"]:
		for node in tree.get_nodes_in_group(group_name):
			if not (node is Node2D):
				continue
			if "is_stump" in node and bool(node.get("is_stump")) and not show_tree_stumps:
				continue
			var cell: Vector2i = DungeonGrid.from_world((node as Node2D).global_position)
			if seen.has(cell):
				continue
			if interior.size.x > 0 and not interior.has_point(cell):
				continue
			if not _cell_revealed(reveal, cell):
				continue
			seen[cell] = true
			out.append(cell)
	return out


## Harness / debug: active scattered mines on revealed cells (depleted omitted).
func collect_revealed_mine_cells(reveal: Node, interior: Rect2i = Rect2i()) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var tree := get_tree()
	if tree == null:
		return out
	if interior == Rect2i():
		interior = _interior_rect()
	var seen: Dictionary = {}
	var nodes: Array = []
	for node in tree.get_nodes_in_group("scattered_mines"):
		nodes.append(node)
	for node in tree.get_nodes_in_group("mines"):
		if not nodes.has(node):
			nodes.append(node)
	for node in nodes:
		if not (node is Node2D):
			continue
		if "is_depleted" in node and bool(node.get("is_depleted")):
			continue
		var cell: Vector2i = DungeonGrid.from_world((node as Node2D).global_position)
		if seen.has(cell):
			continue
		if interior.size.x > 0 and not interior.has_point(cell):
			continue
		if not _cell_revealed(reveal, cell):
			continue
		seen[cell] = true
		out.append(cell)
	return out


## Harness / debug: dungeon wall footprint cells that are revealed.
## Real walls are WallDoodad under generated_dungeon_tiles (have wall_type).
## Group "wall" is also accepted for harness / authored markers.
func collect_revealed_wall_cells(reveal: Node, interior: Rect2i = Rect2i()) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var tree := get_tree()
	if tree == null:
		return out
	if interior == Rect2i():
		interior = _interior_rect()
	var seen: Dictionary = {}
	var nodes: Array = []
	for node in tree.get_nodes_in_group("generated_dungeon_tiles"):
		if "wall_type" in node:
			nodes.append(node)
	for node in tree.get_nodes_in_group("wall"):
		if not nodes.has(node):
			nodes.append(node)
	for node in nodes:
		if not (node is Node2D):
			continue
		var cell: Vector2i = DungeonGrid.from_world((node as Node2D).global_position)
		if seen.has(cell):
			continue
		if interior.size.x > 0 and not interior.has_point(cell):
			continue
		if not _cell_revealed(reveal, cell):
			continue
		seen[cell] = true
		out.append(cell)
	return out


func _draw_buildings(ci: Control, interior: Rect2i, cell_px: float, origin: Vector2, reveal: Node) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var nodes: Array = []
	var root: Node = tree.get_first_node_in_group("building_root")
	if root != null:
		for child in root.get_children():
			nodes.append(child)
	for node in tree.get_nodes_in_group("buildings"):
		if not nodes.has(node):
			nodes.append(node)
	for node in nodes:
		if not (node is Node2D):
			continue
		if "is_ghost" in node and bool(node.get("is_ghost")):
			continue
		if "destroyed" in node and bool(node.get("destroyed")):
			continue
		var cell: Vector2i = DungeonGrid.from_world((node as Node2D).global_position)
		if not interior.has_point(cell):
			continue
		if not _cell_revealed(reveal, cell):
			continue
		var center := origin + Vector2(
			(float(cell.x - interior.position.x) + 0.5) * cell_px,
			(float(cell.y - interior.position.y) + 0.5) * cell_px
		)
		_draw_pip_tex(ci, center, cell_px, _tex_building, BUILDING_COLOR)


func _draw_markers(ci: Control, interior: Rect2i, cell_px: float, origin: Vector2, reveal: Node) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("players"):
		if not _marker_actor_alive(node):
			continue
		if not (node is Node2D):
			continue
		var cell: Vector2i = DungeonGrid.from_world((node as Node2D).global_position)
		if not interior.has_point(cell):
			continue
		var show_pp := true
		if role_is_dm and not debug_reveal_all:
			show_pp = reveal != null and bool(reveal.call("is_dm_revealed", cell))
		if show_pp:
			var center := origin + Vector2(
				(float(cell.x - interior.position.x) + 0.5) * cell_px,
				(float(cell.y - interior.position.y) + 0.5) * cell_px
			)
			_draw_pip_tex(ci, center, cell_px, _tex_pp, PP_PIP)

	var dm_node: Node = null
	if DmManager.dm != null and is_instance_valid(DmManager.dm):
		dm_node = DmManager.dm
	else:
		dm_node = tree.get_first_node_in_group("dm")
		if dm_node == null:
			dm_node = tree.get_first_node_in_group("DungeonMaster")
	if dm_node == null or not _marker_actor_alive(dm_node) or not (dm_node is Node2D):
		return
	var dm_cell: Vector2i = DungeonGrid.from_world((dm_node as Node2D).global_position)
	if not interior.has_point(dm_cell):
		return
	var show_dm := true
	if not role_is_dm and not debug_reveal_all:
		show_dm = reveal != null and bool(reveal.call("is_pp_revealed", dm_cell))
	if show_dm:
		var dm_center := origin + Vector2(
			(float(dm_cell.x - interior.position.x) + 0.5) * cell_px,
			(float(dm_cell.y - interior.position.y) + 0.5) * cell_px
		)
		_draw_pip_tex(ci, dm_center, cell_px, _tex_dm, DM_PIP)


func _draw_pip_tex(ci: Control, center: Vector2, cell_px: float, tex: Texture2D, color: Color) -> void:
	# Pips: max(cell_px, minimap_pip_min_px), centered. Fog/zone/wall fills stay cell-sized.
	var pip: float = maxf(cell_px, minimap_pip_min_px)
	if tex != null:
		var rect := Rect2(center - Vector2(pip, pip) * 0.5, Vector2(pip, pip))
		ci.draw_texture_rect(tex, rect, false)
	else:
		ci.draw_circle(center, pip * 0.45, color)


func _marker_actor_alive(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if node.has_method("is_downed") and bool(node.call("is_downed")):
		return false
	if "hitpoints" in node and int(node.get("hitpoints")) <= 0:
		return false
	if "state_machine" in node:
		var sm = node.get("state_machine")
		if sm != null and "current_state" in sm and sm.current_state != null:
			var sn: String = str(sm.current_state.name).to_lower()
			if sn == "death" or sn == "respawn_wait":
				return false
	return true


func _interior_rect() -> Rect2i:
	var tree := get_tree()
	if tree == null:
		return Rect2i()
	var level: Node = tree.get_first_node_in_group("level_manager")
	if level == null:
		return Rect2i()
	if "map_bounds" in level:
		var mb = level.get("map_bounds")
		if mb != null and mb.has_method("get_interior"):
			return mb.get_interior()
	return Rect2i()
