class_name FantasyZone extends Zone

const DEFAULT_POCKET_DURATION := 8.0
const POCKET_OVERLAY_PATH := "res://sprites/fantasy_pocket_overlay.png"
const BLIZZARD_OVERLAY_PATH := "res://sprites/blizzard_overlay.png"
const BLIZZARD_FALL_VFX := preload("res://spells/blizzard/blizzard_fall_vfx.tscn")
const BlizzardIceDrawScript = preload("res://spells/blizzard/blizzard_ice_draw.gd")

var claim: FantasyClaim = FantasyClaim.new()
var _pocket_overlay_root: Node2D = null
var _pocket_overlay_texture: Texture2D = null
var _blizzard_overlay_texture: Texture2D = null
var _blizzard_fall_vfx: Dictionary = {}

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

func spawn_pocket(origin: Vector2i, size: Vector2i, duration: float = DEFAULT_POCKET_DURATION, overlay: String = "") -> int:
	if not _is_claim_host():
		_rpc_request_spawn_pocket.rpc_id(1, origin, size, duration)
		return -1
	_sync_claim_home()
	var clipped: Rect2i = clip_pocket_rect(Rect2i(origin, size))
	var pocket: Dictionary = claim.add_pocket(clipped, duration, _claim_now(), overlay)
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

func expire_due(now: float = -1.0) -> PackedInt32Array:
	if not _is_claim_host():
		return PackedInt32Array()
	var t: float = claim_now() if now < 0.0 else now
	var expired: PackedInt32Array = claim.expire_due(t)
	if expired.is_empty():
		return expired
	for pocket_id in expired:
		SignalBus.fantasy_pocket_expired.emit(int(pocket_id))
	SignalBus.fantasy_claim_changed.emit()
	_rebuild_home_overlay()
	_broadcast_claim()
	return expired

func claim_now() -> float:
	return _claim_now()

func _process(_delta: float) -> void:
	if _is_claim_host():
		expire_due()

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
	if _blizzard_overlay_texture == null:
		_blizzard_overlay_texture = load(BLIZZARD_OVERLAY_PATH) as Texture2D
	if home_rect.size.x > 0 and home_rect.size.y > 0 and _home_overlay_texture:
		for y in range(home_rect.position.y, home_rect.end.y):
			for x in range(home_rect.position.x, home_rect.end.x):
				var cell := Vector2i(x, y)
				if claim.overlay_kind_for_cell(cell) == "home":
					_place_overlay_sprite(_home_overlay_root, _home_overlay_texture, cell, 0, true)
	for cell in claim.pocket_cells():
		if claim.overlay_kind_for_cell(cell) != "pocket":
			continue
		var tex: Texture2D = _overlay_texture_for_pocket_cell(cell)
		if tex == null or tex == _blizzard_overlay_texture:
			continue
		_place_overlay_sprite(_pocket_overlay_root, tex, cell, 1, true)
	for pocket in claim.pockets:
		if str(pocket.get("overlay", "")) == "blizzard":
			_place_blizzard_ice_wash(pocket)
	_sync_blizzard_fall_vfx()

func _sync_blizzard_fall_vfx() -> void:
	var live: Dictionary = {}
	for pocket in claim.pockets:
		if str(pocket.get("overlay", "")) != "blizzard":
			continue
		var pocket_id: int = int(pocket["id"])
		var cell_rect: Rect2i = pocket["rect"]
		if cell_rect.size.x <= 0 or cell_rect.size.y <= 0:
			continue
		live[pocket_id] = cell_rect
	var stale: Array = []
	for pocket_id in _blizzard_fall_vfx.keys():
		if not live.has(pocket_id):
			stale.append(pocket_id)
	for pocket_id in stale:
		var node: Node = _blizzard_fall_vfx[pocket_id]
		_blizzard_fall_vfx.erase(pocket_id)
		if is_instance_valid(node):
			if node.get_parent():
				node.get_parent().remove_child(node)
			node.queue_free()
	for pocket_id in live.keys():
		var cell_rect: Rect2i = live[pocket_id]
		var world: Rect2 = _pocket_visual_rect(get_pocket(pocket_id), cell_rect)
		var node: Node = _blizzard_fall_vfx.get(pocket_id, null)
		if node == null or not is_instance_valid(node):
			node = BLIZZARD_FALL_VFX.instantiate()
			node.name = "BlizzardFall_%d" % pocket_id
			_blizzard_vfx_host().add_child(node)
			_blizzard_fall_vfx[pocket_id] = node
		if node.has_method("configure"):
			node.call("configure", world)

func _blizzard_vfx_host() -> Node:
	var tree := get_tree()
	if tree:
		var level: Node = tree.get_first_node_in_group("level_manager")
		if level:
			return level
	return self

func live_blizzard_fall_count() -> int:
	var n: int = 0
	for pocket_id in _blizzard_fall_vfx.keys():
		var node: Node = _blizzard_fall_vfx[pocket_id]
		if is_instance_valid(node):
			n += 1
	return n

func _overlay_texture_for_pocket_cell(cell: Vector2i) -> Texture2D:
	var pocket: Dictionary = get_pocket(claim.winning_pocket_id(cell))
	if not pocket.is_empty() and str(pocket.get("overlay", "")) == "blizzard":
		return _blizzard_overlay_texture
	return _pocket_overlay_texture

func _pocket_visual_rect(pocket: Dictionary, cell_rect: Rect2i = Rect2i()) -> Rect2:
	if pocket.get("world_rect") is Rect2:
		var world_rect: Rect2 = pocket["world_rect"]
		if world_rect.size.x > 0.0 and world_rect.size.y > 0.0:
			return world_rect
	var rect: Rect2i = cell_rect
	if pocket.get("rect") is Rect2i:
		rect = pocket["rect"]
	return cell_world_rect(rect)

func _place_blizzard_ice_wash(pocket: Dictionary) -> void:
	if _pocket_overlay_root == null:
		return
	var visual: Rect2 = _pocket_visual_rect(pocket)
	if visual.size.x <= 0.0 or visual.size.y <= 0.0:
		return
	var cells: Vector2i = DmManager.BLIZZARD_POCKET_CELLS
	if pocket.get("rect") is Rect2i:
		var pocket_rect: Rect2i = pocket["rect"]
		if pocket_rect.size.x > 0 and pocket_rect.size.y > 0:
			cells = pocket_rect.size
	BlizzardIceDrawScript.attach_grid(_pocket_overlay_root, visual.position - global_position, cells, 1)

func _ensure_pocket_overlay_root() -> void:
	if _pocket_overlay_root != null and is_instance_valid(_pocket_overlay_root):
		return
	_pocket_overlay_root = get_node_or_null("PocketOverlay") as Node2D
	if _pocket_overlay_root == null:
		_pocket_overlay_root = Node2D.new()
		_pocket_overlay_root.name = "PocketOverlay"
		add_child(_pocket_overlay_root)
	_pocket_overlay_root.visible = true
	_pocket_overlay_root.z_as_relative = false
	_pocket_overlay_root.y_sort_enabled = false

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
