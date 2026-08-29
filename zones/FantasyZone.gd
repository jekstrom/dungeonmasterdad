class_name FantasyZone extends Zone

const DEFAULT_POCKET_DURATION := 8.0
const POCKET_OVERLAY_PATH := "res://sprites/fantasy_pocket_overlay.png"

var claim: FantasyClaim = FantasyClaim.new()
var _pocket_overlay_root: Node2D = null
var _pocket_overlay_texture: Texture2D = null

func _ready() -> void:
	super._ready()
	add_to_group("FantasyZone")
	# Home CollisionShape2D is a monitoring Area2D for claim/detection, not a wall.
	monitoring = true
	monitorable = true
	_discard_exclusion_body()
	_sync_claim_home()
	if not SignalBus.fantasy_pocket_requested.is_connected(_on_fantasy_pocket_requested):
		SignalBus.fantasy_pocket_requested.connect(_on_fantasy_pocket_requested)
	if not multiplayer.peer_connected.is_connected(_on_claim_peer_connected):
		multiplayer.peer_connected.connect(_on_claim_peer_connected)
	_rebuild_home_overlay()
	SignalBus.fantasy_claim_changed.emit()

func _discard_exclusion_body() -> void:
	var leftover := get_node_or_null("Exclusion")
	if leftover != null:
		leftover.queue_free()

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
	if not _is_claim_host():
		_rpc_request_spawn_pocket.rpc_id(1, origin, size, duration)
		return -1
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
	_broadcast_claim()
	return pocket_id

func expire_pocket(pocket_id: int) -> bool:
	if not _is_claim_host():
		return false
	if not claim.expire_pocket(pocket_id):
		return false
	SignalBus.fantasy_pocket_expired.emit(pocket_id)
	SignalBus.fantasy_claim_changed.emit()
	_rebuild_home_overlay()
	_broadcast_claim()
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
	_broadcast_claim()

func _on_map_bounds_committed(interior: Rect2i) -> void:
	super._on_map_bounds_committed(interior)
	_sync_claim_home()
	_clip_live_pockets()
	SignalBus.fantasy_home_changed.emit(home_rect)
	SignalBus.fantasy_claim_changed.emit()
	_broadcast_claim()

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
	_broadcast_claim()

func _is_claim_host() -> bool:
	if multiplayer.multiplayer_peer == null:
		return true
	return multiplayer.is_server()

func build_claim_sync_payload() -> Dictionary:
	_sync_claim_home()
	var payload: Dictionary = claim.to_sync_dict(_claim_now())
	payload["fantasy_level"] = int(DmManager.fantasy_level)
	return payload

func apply_claim_sync_payload(payload: Dictionary) -> void:
	claim.apply_sync_dict(payload, _claim_now())
	home_rect = claim.home_rect
	if payload.has("fantasy_level") and not _is_claim_host():
		DmManager.fantasy_level = int(payload["fantasy_level"])
	if home_rect.size.x > 0 and home_rect.size.y > 0:
		var world_origin: Vector2 = DungeonGrid.to_world(home_rect.position)
		var world_size: Vector2 = Vector2(home_rect.size) * DungeonGrid.CELL_PX
		global_position = world_origin + world_size * 0.5
		_apply_rect_collision(world_size)
	_rebuild_home_overlay()
	SignalBus.fantasy_claim_changed.emit()

func _broadcast_claim() -> void:
	if not Lobby.is_network_server():
		return
	_rpc_apply_claim.rpc(build_claim_sync_payload())

func _on_claim_peer_connected(peer_id: int) -> void:
	if not Lobby.is_network_server():
		return
	_rpc_apply_claim.rpc_id(peer_id, build_claim_sync_payload())

@rpc("authority", "reliable")
func _rpc_apply_claim(payload: Dictionary) -> void:
	if Lobby.is_network_server():
		return
	apply_claim_sync_payload(payload)

@rpc("any_peer", "reliable")
func _rpc_request_spawn_pocket(origin: Vector2i, size: Vector2i, duration: float) -> void:
	if not _is_claim_host():
		return
	spawn_pocket(origin, size, duration)
