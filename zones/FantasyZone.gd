class_name FantasyZone extends Zone

const DEFAULT_POCKET_DURATION := 8.0
const POCKET_OVERLAY_PATH := "res://sprites/fantasy_pocket_overlay.png"
const EXCLUSION_LAYER := 32
const ESCAPE_SEARCH_RADIUS := 24

var claim: FantasyClaim = FantasyClaim.new()
var _pocket_overlay_root: Node2D = null
var _pocket_overlay_texture: Texture2D = null
var _exclusion_body: StaticBody2D = null

func _ready() -> void:
	super._ready()
	add_to_group("FantasyZone")
	_sync_claim_home()
	if not SignalBus.fantasy_pocket_requested.is_connected(_on_fantasy_pocket_requested):
		SignalBus.fantasy_pocket_requested.connect(_on_fantasy_pocket_requested)
	_rebuild_home_overlay()

func is_position_within_zone(pos: Vector2) -> bool:
	return is_claimed_world(pos)

func contains_world_position(world: Vector2) -> bool:
	_sync_claim_home()
	return claim.is_claimed_world(world)

func contains_world_rect(rect: Rect2) -> bool:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return false
	var inset := 0.001
	var corners: Array[Vector2] = [
		rect.position,
		Vector2(rect.end.x - inset, rect.position.y),
		Vector2(rect.end.x - inset, rect.end.y - inset),
		Vector2(rect.position.x, rect.end.y - inset),
	]
	for corner in corners:
		if not is_claimed_world(corner):
			return false
	return true

func is_claimed_cell(cell: Vector2i) -> bool:
	_sync_claim_home()
	return claim.is_claimed_cell(cell)

func is_claimed_world(world: Vector2) -> bool:
	_sync_claim_home()
	return claim.is_claimed_world(world)

func overlay_kind_for_cell(cell: Vector2i) -> String:
	_sync_claim_home()
	return claim.overlay_kind_for_cell(cell)

func winning_pocket_id(cell: Vector2i) -> int:
	_sync_claim_home()
	return claim.winning_pocket_id(cell)

func get_pocket(pocket_id: int) -> Dictionary:
	for pocket in claim.pockets:
		if int(pocket["id"]) == pocket_id:
			return pocket
	return {}

func spawn_pocket(origin: Vector2i, size: Vector2i, duration: float = DEFAULT_POCKET_DURATION) -> int:
	_sync_claim_home()
	var clipped: Rect2i = clip_pocket_rect(Rect2i(origin, size))
	var pocket: Dictionary = claim.add_pocket(clipped, duration, _claim_now())
	if pocket.is_empty():
		return -1
	var pocket_id: int = int(pocket["id"])
	var tree := get_tree()
	if tree:
		var timer: SceneTreeTimer = tree.create_timer(duration)
		timer.timeout.connect(_on_pocket_timeout.bind(pocket_id))
	SignalBus.fantasy_pocket_created.emit(pocket_id, clipped, duration)
	SignalBus.fantasy_claim_changed.emit()
	_rebuild_home_overlay()
	return pocket_id

func expire_pocket(pocket_id: int) -> bool:
	if not claim.expire_pocket(pocket_id):
		return false
	SignalBus.fantasy_pocket_expired.emit(pocket_id)
	SignalBus.fantasy_claim_changed.emit()
	_rebuild_home_overlay()
	return true

func _on_pocket_timeout(pocket_id: int) -> void:
	expire_pocket(pocket_id)

func _on_fantasy_pocket_requested(origin: Vector2i, size: Vector2i, duration: float) -> void:
	spawn_pocket(origin, size, duration)

func _sync_claim_home() -> void:
	claim.home_rect = home_rect

func _claim_now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0

func _rebuild_home_overlay() -> void:
	_sync_claim_home()
	_ensure_home_overlay_root()
	_ensure_pocket_overlay_root()
	_clear_overlay_children(_home_overlay_root)
	_clear_overlay_children(_pocket_overlay_root)
	if _home_overlay_texture == null:
		_home_overlay_texture = load(FANTASY_HOME_OVERLAY_PATH) as Texture2D
	if _pocket_overlay_texture == null:
		_pocket_overlay_texture = load(POCKET_OVERLAY_PATH) as Texture2D
	if home_rect.size.x > 0 and home_rect.size.y > 0 and _home_overlay_texture:
		for y in range(home_rect.position.y, home_rect.end.y):
			for x in range(home_rect.position.x, home_rect.end.x):
				var cell := Vector2i(x, y)
				if claim.overlay_kind_for_cell(cell) == "home":
					_place_overlay_sprite(_home_overlay_root, _home_overlay_texture, cell, 0)
	if _pocket_overlay_texture:
		for cell in claim.pocket_cells():
			if claim.overlay_kind_for_cell(cell) == "pocket":
				_place_overlay_sprite(_pocket_overlay_root, _pocket_overlay_texture, cell, 1)
	_rebuild_exclusion()

func _ensure_pocket_overlay_root() -> void:
	if _pocket_overlay_root != null and is_instance_valid(_pocket_overlay_root):
		return
	_pocket_overlay_root = get_node_or_null("PocketOverlay") as Node2D
	if _pocket_overlay_root == null:
		_pocket_overlay_root = Node2D.new()
		_pocket_overlay_root.name = "PocketOverlay"
		add_child(_pocket_overlay_root)

func _on_map_bounds_cleared() -> void:
	super._on_map_bounds_cleared()
	claim.clear_pockets()
	_rebuild_home_overlay()
	SignalBus.fantasy_claim_changed.emit()

func _on_map_bounds_committed(interior: Rect2i) -> void:
	super._on_map_bounds_committed(interior)
	_sync_claim_home()
	_clip_live_pockets()
	SignalBus.fantasy_home_changed.emit(home_rect)
	SignalBus.fantasy_claim_changed.emit()

func _clip_live_pockets() -> void:
	var expired: Array[int] = []
	for pocket in claim.pockets:
		var clipped: Rect2i = clip_pocket_rect(pocket["rect"])
		pocket["rect"] = clipped
		if clipped.size.x <= 0 or clipped.size.y <= 0:
			expired.append(int(pocket["id"]))
	for pocket_id in expired:
		expire_pocket(pocket_id)

func on_level_changed(new_level: int) -> void:
	super.on_level_changed(new_level)
	_sync_claim_home()
	SignalBus.fantasy_home_changed.emit(home_rect)
	SignalBus.fantasy_claim_changed.emit()

func _physics_process(_delta: float) -> void:
	displace_paper_pushers()

func _is_occupancy_host() -> bool:
	if multiplayer.multiplayer_peer == null:
		return true
	return multiplayer.is_server()

func displace_paper_pushers() -> void:
	if not _is_occupancy_host():
		return
	var tree := get_tree()
	if tree == null:
		return
	_sync_claim_home()
	var reserved: Dictionary = {}
	for node in tree.get_nodes_in_group("players"):
		if node == null or not is_instance_valid(node):
			continue
		if not (node is Node2D):
			continue
		if node.is_in_group("dm"):
			continue
		var body := node as Node2D
		if not is_claimed_world(body.global_position):
			continue
		var dest: Vector2 = _escape_world(body.global_position, reserved)
		_apply_player_displacement(body, dest)

func _apply_player_displacement(body: Node2D, dest: Vector2) -> void:
	body.global_position = dest
	if body is CharacterBody2D:
		(body as CharacterBody2D).velocity = Vector2.ZERO
	if not Lobby.is_network_server():
		return
	if not body.has_method("apply_interior_clamp"):
		return
	var owner_id: int = body.get_multiplayer_authority()
	if owner_id <= 0 or owner_id == multiplayer.get_unique_id():
		return
	body.apply_interior_clamp.rpc_id(owner_id, dest)

func _escape_world(from: Vector2, reserved: Dictionary) -> Vector2:
	var origin: Vector2i = DungeonGrid.from_world(from)
	for radius in range(0, ESCAPE_SEARCH_RADIUS + 1):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if radius > 0 and maxi(absi(dx), absi(dy)) != radius:
					continue
				var cell := origin + Vector2i(dx, dy)
				if not _is_escape_cell(cell):
					continue
				if reserved.has(cell):
					continue
				reserved[cell] = true
				return DungeonGrid.to_world_center(cell)
	return _reality_spawn_world(reserved)

func _is_escape_cell(cell: Vector2i) -> bool:
	if is_claimed_cell(cell):
		return false
	var bounds: MapBounds = _level_map_bounds()
	if bounds == null:
		return true
	if not bounds.is_interior_cell(cell):
		return false
	if bounds.is_cliff_cell(cell):
		return false
	return true

func _reality_spawn_world(reserved: Dictionary) -> Vector2:
	var level: Node = _level_manager()
	if level and level.has_method("west_spawn_cells"):
		var cells: Array = level.west_spawn_cells()
		for cell in cells:
			var spawn_cell: Vector2i = cell
			if reserved.has(spawn_cell):
				continue
			reserved[spawn_cell] = true
			return DungeonGrid.to_world_center(spawn_cell)
	if level and level.has_method("take_west_spawn_world"):
		return level.take_west_spawn_world()
	var reality: Node = get_tree().get_first_node_in_group("RealityZone") if get_tree() else null
	if reality and reality.has_method("get_next_spawn_point"):
		return reality.get_next_spawn_point()
	return DungeonGrid.to_world_center(Vector2i(0, 0))

func _rebuild_exclusion() -> void:
	_ensure_exclusion_body()
	for child in _exclusion_body.get_children():
		_exclusion_body.remove_child(child)
		child.queue_free()
	_sync_claim_home()
	var rects: Array[Rect2i] = []
	if home_rect.size.x > 0 and home_rect.size.y > 0:
		rects.append(home_rect)
	for pocket in claim.pockets:
		var rect: Rect2i = pocket["rect"]
		if rect.size.x > 0 and rect.size.y > 0:
			rects.append(rect)
	for rect in rects:
		var shape_node := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		var world_size: Vector2 = Vector2(rect.size) * DungeonGrid.CELL_PX
		shape.size = world_size
		shape_node.shape = shape
		var world_origin: Vector2 = DungeonGrid.to_world(rect.position)
		shape_node.position = world_origin + world_size * 0.5 - global_position
		_exclusion_body.add_child(shape_node)

func _ensure_exclusion_body() -> void:
	if _exclusion_body != null and is_instance_valid(_exclusion_body):
		return
	_exclusion_body = get_node_or_null("Exclusion") as StaticBody2D
	if _exclusion_body == null:
		_exclusion_body = StaticBody2D.new()
		_exclusion_body.name = "Exclusion"
		add_child(_exclusion_body)
	_exclusion_body.collision_layer = EXCLUSION_LAYER
	_exclusion_body.collision_mask = 0

