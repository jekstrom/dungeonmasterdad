class_name Zone extends Area2D

const SPRITE_GRID_Y := -63.0
const HOME_OVERLAY_PATH := "res://sprites/reality_home_overlay.png"
const FANTASY_HOME_OVERLAY_PATH := "res://sprites/fantasy_home_overlay.png"

@export var base_radius: float = 100.0
@export var zone_color: Color = Color(0, 1, 0, 0.3)
@export var is_reality: bool = false
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var radius
var home_rect: Rect2i = Rect2i()
var _home_overlay_root: Node2D = null
var _home_overlay_texture: Texture2D = null
var _queued_rect_collision: Vector2 = Vector2.ZERO
var _rect_collision_queued: bool = false
static var _resolving_homes: bool = false
static var debug_claim_overlays: bool = false

static func overlay_world_rect(cell_rect: Rect2i) -> Rect2:
	if cell_rect.size.x <= 0 or cell_rect.size.y <= 0:
		return Rect2()
	var origin := DungeonGrid.to_world(cell_rect.position) + Vector2(
		-DungeonGrid.SPRITE_HALF_X,
		SPRITE_GRID_Y - DungeonGrid.SPRITE_HALF_X
	)
	return Rect2(origin, Vector2(cell_rect.size) * DungeonGrid.CELL_PX)

static func cell_world_rect(cell_rect: Rect2i) -> Rect2:
	if cell_rect.size.x <= 0 or cell_rect.size.y <= 0:
		return Rect2()
	return Rect2(DungeonGrid.to_world(cell_rect.position), Vector2(cell_rect.size) * DungeonGrid.CELL_PX)

func _ready() -> void:
	visible = true
	collision_layer = 0
	collision_mask = 0
	if not is_in_group("claim_zone"):
		add_to_group("claim_zone")
	if is_reality:
		if not PlayerManager.reality_level_changed.is_connected(on_level_changed):
			PlayerManager.reality_level_changed.connect(on_level_changed)
	else:
		if not DmManager.fantasy_level_changed.is_connected(on_level_changed):
			DmManager.fantasy_level_changed.connect(on_level_changed)
	if not SignalBus.map_bounds_committed.is_connected(_on_map_bounds_committed):
		SignalBus.map_bounds_committed.connect(_on_map_bounds_committed)
	if not SignalBus.map_bounds_cleared.is_connected(_on_map_bounds_cleared):
		SignalBus.map_bounds_cleared.connect(_on_map_bounds_cleared)
	clip_home_to_interior()

func _draw() -> void:
	# Home look is cell overlays (Reality and Fantasy). Skip debug circle/rect.
	return

func contains_world_position(world: Vector2) -> bool:
	if home_rect.size.x <= 0 or home_rect.size.y <= 0:
		return false
	return home_rect.has_point(DungeonGrid.from_world(world))

func contains_world_rect(rect: Rect2) -> bool:
	if home_rect.size.x <= 0 or home_rect.size.y <= 0:
		return false
	var home_world := Rect2(
		DungeonGrid.to_world(home_rect.position),
		Vector2(home_rect.size) * DungeonGrid.CELL_PX
	)
	return home_world.encloses(rect)

func on_level_changed(_new_level: int) -> void:
	clip_home_to_interior()

func _on_map_bounds_committed(_interior: Rect2i) -> void:
	clip_home_to_interior()

func _on_map_bounds_cleared() -> void:
	home_rect = Rect2i()
	_clear_home_overlay()
	queue_redraw()

func clip_home_to_interior() -> void:
	var bounds: MapBounds = _level_map_bounds()
	if bounds == null or not bounds.has_committed_bounds():
		return
	var interior: Rect2i = bounds.get_interior()
	home_rect = proposed_home_rect(bounds, interior)
	_resolve_overlapping_homes(bounds, interior)
	_apply_clipped_home_presentation()

func clip_pocket_rect(rect: Rect2i) -> Rect2i:
	var bounds: MapBounds = _level_map_bounds()
	if bounds == null:
		return Rect2i()
	return bounds.intersect_interior(rect)

func proposed_home_rect(bounds: MapBounds, interior: Rect2i) -> Rect2i:
	if is_reality:
		return _proposed_reality_home(bounds, interior)
	return _proposed_fantasy_home(bounds, interior)

func _proposed_reality_home(bounds: MapBounds, interior: Rect2i) -> Rect2i:
	var width: int = _home_width_from_radius() + maxi(0, _current_zone_level())
	var proposed := Rect2i(interior.position, Vector2i(width, interior.size.y))
	return bounds.intersect_interior(proposed)

func _proposed_fantasy_home(bounds: MapBounds, interior: Rect2i) -> Rect2i:
	var seed_rect: Rect2i = _fantasy_seed_rect(interior)
	var growth: int = maxi(0, _current_zone_level())
	var proposed := Rect2i(
		seed_rect.position - Vector2i(growth, growth),
		seed_rect.size + Vector2i(growth * 2, growth * 2)
	)
	return bounds.intersect_interior(proposed)

func _place_reality_home(bounds: MapBounds, interior: Rect2i) -> void:
	home_rect = _proposed_reality_home(bounds, interior)

func _place_fantasy_home(bounds: MapBounds, interior: Rect2i) -> void:
	home_rect = _proposed_fantasy_home(bounds, interior)

func _resolve_overlapping_homes(bounds: MapBounds, interior: Rect2i) -> void:
	if _resolving_homes:
		return
	var tree := get_tree()
	if tree == null:
		return
	var reality: Node = self if is_reality else tree.get_first_node_in_group("RealityZone")
	var fantasy: Node = self if not is_reality else tree.get_first_node_in_group("FantasyZone")
	if reality == null or fantasy == null:
		return
	if not reality.has_method("proposed_home_rect") or not fantasy.has_method("proposed_home_rect"):
		return
	_resolving_homes = true
	var reality_proposed: Rect2i = reality.proposed_home_rect(bounds, interior)
	var fantasy_proposed: Rect2i = fantasy.proposed_home_rect(bounds, interior)
	var resolved: Array = resolve_home_rects(
		reality_proposed,
		fantasy_proposed,
		int(PlayerManager.reality_level),
		int(DmManager.fantasy_level)
	)
	var reality_rect: Rect2i = resolved[0]
	var fantasy_rect: Rect2i = resolved[1]
	reality.home_rect = reality_rect
	fantasy.home_rect = fantasy_rect
	var peer: Node = fantasy if is_reality else reality
	_apply_peer_resolved_home(peer)
	_resolving_homes = false

func _apply_peer_resolved_home(peer: Node) -> void:
	if peer == null or peer == self:
		return
	if peer.has_method("_sync_claim_home"):
		peer._sync_claim_home()
	if peer.has_method("_apply_clipped_home_presentation"):
		peer._apply_clipped_home_presentation()
	if bool(peer.get("is_reality")):
		SignalBus.reality_home_changed.emit(peer.home_rect)
		SignalBus.reality_claim_changed.emit()
	else:
		SignalBus.fantasy_home_changed.emit(peer.home_rect)
		SignalBus.fantasy_claim_changed.emit()
	if peer.has_method("_broadcast_claim"):
		peer._broadcast_claim()

static func homes_occupy_same_cell(a: Rect2i, b: Rect2i) -> bool:
	var hit: Rect2i = a.intersection(b)
	return hit.size.x > 0 and hit.size.y > 0

static func resolve_home_rects(reality: Rect2i, fantasy: Rect2i, reality_level: int, fantasy_level: int) -> Array:
	if not homes_occupy_same_cell(reality, fantasy):
		return [reality, fantasy]
	if reality_level > fantasy_level:
		return [reality, _shrink_home_off(fantasy, reality, false)]
	if fantasy_level > reality_level:
		return [_shrink_home_off(reality, fantasy, true), fantasy]
	return _retract_equal_homes(reality, fantasy)

static func _shrink_home_off(loser: Rect2i, winner: Rect2i, shrink_from_east: bool) -> Rect2i:
	var hit: Rect2i = loser.intersection(winner)
	if hit.size.x <= 0 or hit.size.y <= 0:
		return loser
	var out: Rect2i = loser
	if shrink_from_east:
		var new_end_x: int = mini(loser.end.x, hit.position.x)
		var new_w: int = new_end_x - loser.position.x
		if new_w <= 0:
			return Rect2i()
		out = Rect2i(loser.position, Vector2i(new_w, loser.size.y))
	else:
		var new_x: int = maxi(loser.position.x, hit.end.x)
		var new_w2: int = loser.end.x - new_x
		if new_w2 <= 0:
			return Rect2i()
		out = Rect2i(Vector2i(new_x, loser.position.y), Vector2i(new_w2, loser.size.y))
	return _shrink_vertical_if_needed(out, winner)

static func _shrink_vertical_if_needed(loser: Rect2i, winner: Rect2i) -> Rect2i:
	var hit: Rect2i = loser.intersection(winner)
	if hit.size.x <= 0 or hit.size.y <= 0:
		return loser
	if hit.position.y <= loser.position.y:
		var new_y: int = hit.end.y
		var new_h: int = loser.end.y - new_y
		if new_h <= 0:
			return Rect2i()
		return Rect2i(Vector2i(loser.position.x, new_y), Vector2i(loser.size.x, new_h))
	var keep_h: int = hit.position.y - loser.position.y
	if keep_h <= 0:
		return Rect2i()
	return Rect2i(loser.position, Vector2i(loser.size.x, keep_h))

static func _retract_equal_homes(reality: Rect2i, fantasy: Rect2i) -> Array:
	var hit: Rect2i = reality.intersection(fantasy)
	if hit.size.x <= 0 or hit.size.y <= 0:
		return [reality, fantasy]
	var ox: int = hit.position.x
	var ow: int = hit.size.x
	var fantasy_end_x: int = fantasy.end.x
	var r: Rect2i = reality
	var f: Rect2i = fantasy
	if ow % 2 == 0:
		var split: int = ox + int(ow / 2)
		var r_w: int = split - reality.position.x
		r = Rect2i() if r_w <= 0 else Rect2i(reality.position, Vector2i(r_w, reality.size.y))
		var f_w: int = fantasy_end_x - split
		f = Rect2i() if f_w <= 0 else Rect2i(Vector2i(split, fantasy.position.y), Vector2i(f_w, fantasy.size.y))
	else:
		var mid: int = ox + int(ow / 2)
		var r_w2: int = mid - reality.position.x
		r = Rect2i() if r_w2 <= 0 else Rect2i(reality.position, Vector2i(r_w2, reality.size.y))
		var f_x: int = mid + 1
		var f_w2: int = fantasy_end_x - f_x
		f = Rect2i() if f_w2 <= 0 else Rect2i(Vector2i(f_x, fantasy.position.y), Vector2i(f_w2, fantasy.size.y))
	if homes_occupy_same_cell(r, f):
		f = _shrink_home_off(f, r, false)
		if homes_occupy_same_cell(r, f):
			r = _shrink_home_off(r, f, true)
	return [r, f]

func _fantasy_seed_rect(interior: Rect2i) -> Rect2i:
	var level_node: Node = _level_manager()
	if level_node and level_node.has_method("dungeon_cell_bounds"):
		var dungeon: Rect2i = level_node.dungeon_cell_bounds()
		if dungeon.size.x > 0 and dungeon.size.y > 0:
			return dungeon
	var width: int = _home_width_from_radius()
	return Rect2i(
		Vector2i(interior.end.x - width, interior.position.y),
		Vector2i(width, interior.size.y)
	)

func _apply_clipped_home_presentation() -> void:
	if home_rect.size.x <= 0 or home_rect.size.y <= 0:
		_clear_home_overlay()
		if _resolve_collision_shape():
			collision_shape_2d.disabled = true
		return
	var world_origin: Vector2 = DungeonGrid.to_world(home_rect.position)
	var world_size: Vector2 = Vector2(home_rect.size) * DungeonGrid.CELL_PX
	global_position = world_origin + world_size * 0.5
	_apply_rect_collision(world_size)
	_rebuild_home_overlay()
	queue_redraw()

func _apply_rect_collision(world_size: Vector2) -> void:
	_queued_rect_collision = world_size
	if not is_inside_tree():
		_apply_rect_collision_now()
		return
	if _rect_collision_queued:
		return
	_rect_collision_queued = true
	call_deferred("_apply_rect_collision_now")

func _apply_rect_collision_now() -> void:
	_rect_collision_queued = false
	if not _resolve_collision_shape():
		return
	var world_size: Vector2 = _queued_rect_collision
	collision_shape_2d.scale = Vector2.ONE
	collision_shape_2d.position = Vector2.ZERO
	collision_shape_2d.disabled = false
	var rect_shape: RectangleShape2D
	if collision_shape_2d.shape is RectangleShape2D:
		rect_shape = collision_shape_2d.shape as RectangleShape2D
		if not rect_shape.resource_local_to_scene:
			rect_shape = rect_shape.duplicate() as RectangleShape2D
			rect_shape.resource_local_to_scene = true
			collision_shape_2d.shape = rect_shape
	else:
		rect_shape = RectangleShape2D.new()
		rect_shape.resource_local_to_scene = true
		collision_shape_2d.shape = rect_shape
	rect_shape.size = world_size

func _rebuild_home_overlay() -> void:
	_ensure_home_overlay_root()
	_clear_overlay_children(_home_overlay_root)
	if _home_overlay_texture == null:
		var path: String = HOME_OVERLAY_PATH if is_reality else FANTASY_HOME_OVERLAY_PATH
		_home_overlay_texture = load(path) as Texture2D
	if _home_overlay_texture == null:
		return
	for y in range(home_rect.position.y, home_rect.end.y):
		for x in range(home_rect.position.x, home_rect.end.x):
			_place_overlay_sprite(_home_overlay_root, _home_overlay_texture, Vector2i(x, y), 0, true)

func _place_overlay_sprite(parent: Node2D, texture: Texture2D, cell: Vector2i, z: int, debug_only: bool = true, overlay_material: Material = null, snap_cell_center: bool = false, world_pos: Vector2 = Vector2(INF, INF)) -> void:
	if parent == null or texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.z_as_relative = false
	sprite.z_index = z
	if is_finite(world_pos.x) and is_finite(world_pos.y):
		sprite.position = world_pos - global_position
	elif snap_cell_center:
		sprite.position = DungeonGrid.to_world_center(cell) - global_position
	else:
		sprite.position = DungeonGrid.to_world(cell) - global_position + Vector2(0.0, SPRITE_GRID_Y)
	sprite.set_meta("debug_claim_overlay", debug_only)
	sprite.visible = (not debug_only) or debug_claim_overlays
	if overlay_material:
		sprite.material = overlay_material
	parent.add_child(sprite)

func apply_debug_claim_overlay_visibility() -> void:
	for root_name in ["HomeOverlay", "PocketOverlay"]:
		var root: Node = get_node_or_null(root_name)
		if root == null:
			continue
		for child in root.get_children():
			if not (child is CanvasItem):
				continue
			var item: CanvasItem = child
			var debug_only: bool = bool(item.get_meta("debug_claim_overlay", true))
			item.visible = (not debug_only) or debug_claim_overlays

static func set_debug_claim_overlays(on: bool) -> void:
	debug_claim_overlays = on
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for node in tree.get_nodes_in_group("claim_zone"):
		if node.has_method("apply_debug_claim_overlay_visibility"):
			node.apply_debug_claim_overlay_visibility()

func _clear_overlay_children(parent: Node2D) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func _ensure_home_overlay_root() -> void:
	if _home_overlay_root != null and is_instance_valid(_home_overlay_root):
		return
	_home_overlay_root = get_node_or_null("HomeOverlay") as Node2D
	if _home_overlay_root == null:
		_home_overlay_root = Node2D.new()
		_home_overlay_root.name = "HomeOverlay"
		add_child(_home_overlay_root)

func _clear_home_overlay() -> void:
	_clear_overlay_children(_home_overlay_root)

func _home_width_from_radius() -> int:
	return maxi(1, int(ceil(base_radius / DungeonGrid.CELL_PX)))

func _current_zone_level() -> int:
	if is_reality:
		return int(PlayerManager.reality_level)
	return int(DmManager.fantasy_level)

func _level_manager() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("level_manager")

func _level_map_bounds() -> MapBounds:
	var level_node: Node = _level_manager()
	if level_node and level_node.has_method("get_map_bounds"):
		return level_node.get_map_bounds()
	return null

func _resolve_collision_shape() -> bool:
	if collision_shape_2d == null:
		collision_shape_2d = get_node_or_null("CollisionShape2D")
	return collision_shape_2d != null
