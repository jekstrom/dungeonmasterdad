extends Node

## US-033 host-authoritative mini-map fog of war.
## Two isolated sticky reveal sets: pp_shared (all PPs) and dm_private (DM only).
## Clients paint only from replicated state — they never invent reveals.

const VISIT_RADIUS := 3
const ROLE_PP := 0
const ROLE_DM := 1

signal reveal_changed(role: String)

## Vector2i -> true
var pp_shared: Dictionary = {}
var dm_private: Dictionary = {}

var _pp_delta_pending: Dictionary = {}
var _dm_delta_pending: Dictionary = {}
var _flush_queued: bool = false


func _ready() -> void:
	if not SignalBus.map_bounds_cleared.is_connected(_on_map_bounds_cleared):
		SignalBus.map_bounds_cleared.connect(_on_map_bounds_cleared)
	if not Lobby.host_started.is_connected(_on_host_started):
		Lobby.host_started.connect(_on_host_started)
	_ensure_peer_connected_hook()


func _ensure_peer_connected_hook() -> void:
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)


func _has_reveal_authority() -> bool:
	# Same pattern as LevelManager offline commit: real host OR offline peer.
	if Lobby.is_network_server():
		return true
	if not multiplayer.has_multiplayer_peer():
		return true
	return multiplayer.multiplayer_peer is OfflineMultiplayerPeer


func _process(_delta: float) -> void:
	if not _has_reveal_authority():
		return
	_host_tick_living_movers()


func _on_host_started(_player_name = null) -> void:
	if not _has_reveal_authority():
		return
	reset_reveals()
	_ensure_peer_connected_hook()


func _on_map_bounds_cleared() -> void:
	reset_reveals()


func reset_reveals() -> void:
	pp_shared.clear()
	dm_private.clear()
	_pp_delta_pending.clear()
	_dm_delta_pending.clear()
	reveal_changed.emit("pp")
	reveal_changed.emit("dm")


func is_pp_revealed(cell: Vector2i) -> bool:
	return pp_shared.has(cell)


func is_dm_revealed(cell: Vector2i) -> bool:
	return dm_private.has(cell)


func encode_cells(source: Dictionary) -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(source.size() * 2)
	var i := 0
	for cell in source.keys():
		var c: Vector2i = cell
		out[i] = c.x
		out[i + 1] = c.y
		i += 2
	return out


func decode_cells(packed: PackedInt32Array, target: Dictionary) -> void:
	var n: int = packed.size()
	var i := 0
	while i + 1 < n:
		target[Vector2i(packed[i], packed[i + 1])] = true
		i += 2


## Host / harness: expand Chebyshev brush. Sticky. Returns newly added count.
func apply_visit_at(role_or_dm, center: Vector2i) -> int:
	var is_dm: bool = bool(role_or_dm) if typeof(role_or_dm) == TYPE_BOOL else int(role_or_dm) == ROLE_DM
	var target: Dictionary = dm_private if is_dm else pp_shared
	var pending: Dictionary = _dm_delta_pending if is_dm else _pp_delta_pending
	var added := 0
	for dy in range(-VISIT_RADIUS, VISIT_RADIUS + 1):
		for dx in range(-VISIT_RADIUS, VISIT_RADIUS + 1):
			if maxi(absi(dx), absi(dy)) > VISIT_RADIUS:
				continue
			var cell := Vector2i(center.x + dx, center.y + dy)
			if not _cell_allowed(cell):
				continue
			if target.has(cell):
				continue
			target[cell] = true
			pending[cell] = true
			added += 1
	if added > 0:
		reveal_changed.emit("dm" if is_dm else "pp")
		_queue_flush()
	return added


func snapshot_pp() -> PackedInt32Array:
	return encode_cells(pp_shared)


func snapshot_dm() -> PackedInt32Array:
	return encode_cells(dm_private)


func send_late_join_snapshot(peer_id: int, role_or_dm) -> void:
	if not Lobby.is_network_server():
		return
	if peer_id <= 0:
		return
	var is_dm: bool = bool(role_or_dm) if typeof(role_or_dm) == TYPE_BOOL else int(role_or_dm) == ROLE_DM
	if is_dm:
		rpc_snapshot_dm.rpc_id(peer_id, snapshot_dm())
	else:
		rpc_snapshot_pp.rpc_id(peer_id, snapshot_pp())


## Client asks host for the role-appropriate full set (late join / first paint).
@rpc("any_peer", "reliable")
func request_snapshot(is_dm: bool) -> void:
	if not Lobby.is_network_server():
		return
	var peer_id: int = multiplayer.get_remote_sender_id()
	if peer_id <= 0:
		return
	send_late_join_snapshot(peer_id, is_dm)


func request_snapshot_for_local(is_dm: bool) -> void:
	if Lobby.is_network_server():
		return
	if not multiplayer.has_multiplayer_peer():
		return
	if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return
	request_snapshot.rpc_id(1, is_dm)


@rpc("authority", "call_local", "reliable")
func rpc_apply_pp_cells(packed: PackedInt32Array) -> void:
	var before: int = pp_shared.size()
	decode_cells(packed, pp_shared)
	if pp_shared.size() != before:
		reveal_changed.emit("pp")


@rpc("authority", "call_local", "reliable")
func rpc_apply_dm_cells(packed: PackedInt32Array) -> void:
	var before: int = dm_private.size()
	decode_cells(packed, dm_private)
	if dm_private.size() != before:
		reveal_changed.emit("dm")


@rpc("authority", "call_local", "reliable")
func rpc_snapshot_pp(packed: PackedInt32Array) -> void:
	pp_shared.clear()
	decode_cells(packed, pp_shared)
	reveal_changed.emit("pp")


@rpc("authority", "call_local", "reliable")
func rpc_snapshot_dm(packed: PackedInt32Array) -> void:
	dm_private.clear()
	decode_cells(packed, dm_private)
	reveal_changed.emit("dm")


func _host_tick_living_movers() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("players"):
		if not _actor_alive(node):
			continue
		if not (node is Node2D):
			continue
		apply_visit_at(false, DungeonGrid.from_world((node as Node2D).global_position))
	# Also try PlayerManager lookup if present.
	if PlayerManager != null and PlayerManager.has_method("get_player_node_by_id"):
		pass  # group walk already covers living PPs
	var dm_node: Node = null
	if DmManager.dm != null and is_instance_valid(DmManager.dm):
		dm_node = DmManager.dm
	else:
		dm_node = tree.get_first_node_in_group("dm")
		if dm_node == null:
			dm_node = tree.get_first_node_in_group("DungeonMaster")
	if dm_node != null and _actor_alive(dm_node) and dm_node is Node2D:
		apply_visit_at(true, DungeonGrid.from_world((dm_node as Node2D).global_position))


func _actor_alive(node: Node) -> bool:
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


func _cell_allowed(cell: Vector2i) -> bool:
	var tree := get_tree()
	if tree == null:
		return true
	var level: Node = tree.get_first_node_in_group("level_manager")
	if level == null:
		return true
	if "map_bounds" in level:
		var bounds = level.get("map_bounds")
		if bounds != null and bounds.has_method("is_interior_cell") and bounds.has_method("has_committed_bounds"):
			if bool(bounds.has_committed_bounds()):
				return bool(bounds.is_interior_cell(cell))
	return true


func _queue_flush() -> void:
	if not Lobby.is_network_server():
		_pp_delta_pending.clear()
		_dm_delta_pending.clear()
		return
	if _flush_queued:
		return
	_flush_queued = true
	call_deferred("_flush_deltas")


func _flush_deltas() -> void:
	_flush_queued = false
	if not Lobby.is_network_server():
		_pp_delta_pending.clear()
		_dm_delta_pending.clear()
		return
	if not _pp_delta_pending.is_empty():
		var packed: PackedInt32Array = encode_cells(_pp_delta_pending)
		_pp_delta_pending.clear()
		rpc_apply_pp_cells.rpc(packed)
	if not _dm_delta_pending.is_empty():
		var packed_dm: PackedInt32Array = encode_cells(_dm_delta_pending)
		_dm_delta_pending.clear()
		_send_dm_delta(packed_dm)


func _send_dm_delta(packed: PackedInt32Array) -> void:
	var dm_peer := _dm_peer_id()
	if dm_peer <= 0:
		# No known DM peer yet — host still holds truth locally.
		return
	if dm_peer == multiplayer.get_unique_id():
		return
	rpc_apply_dm_cells.rpc_id(dm_peer, packed)


func _on_peer_connected(peer_id: int) -> void:
	if not Lobby.is_network_server():
		return
	_ensure_peer_connected_hook()
	# Role may not be known yet; default PP shared. Widget request_snapshot
	# corrects for DM joiners.
	if _is_dm_peer(peer_id):
		send_late_join_snapshot(peer_id, true)
	else:
		send_late_join_snapshot(peer_id, false)


func _dm_peer_id() -> int:
	if DmManager.dm != null and is_instance_valid(DmManager.dm):
		return int(DmManager.dm.get_multiplayer_authority())
	return -1


func is_dm_peer(peer_id: int) -> bool:
	return _is_dm_peer(peer_id)


func _is_dm_peer(peer_id: int) -> bool:
	if peer_id <= 0:
		return false
	var dm_peer := _dm_peer_id()
	if dm_peer <= 0:
		return false
	return peer_id == dm_peer


## Marker visibility helpers (FR-007).
func should_show_pp_marker(viewer_role_or_dm, pp_cell: Vector2i) -> bool:
	var viewer_is_dm: bool = bool(viewer_role_or_dm) if typeof(viewer_role_or_dm) == TYPE_BOOL else int(viewer_role_or_dm) == ROLE_DM
	if not viewer_is_dm:
		return true
	return is_dm_revealed(pp_cell)


func should_show_dm_marker(viewer_role_or_dm, dm_cell: Vector2i) -> bool:
	var viewer_is_dm: bool = bool(viewer_role_or_dm) if typeof(viewer_role_or_dm) == TYPE_BOOL else int(viewer_role_or_dm) == ROLE_DM
	if viewer_is_dm:
		return true
	return is_pp_revealed(dm_cell)


static func brush_cell_count(radius: int = VISIT_RADIUS) -> int:
	var side: int = radius * 2 + 1
	return side * side


# --- Compatibility shims (role int API used by harness / late-join callers) ---
var pp_shared_reveal: Dictionary:
	get:
		return pp_shared

var dm_reveal: Dictionary:
	get:
		return dm_private


func is_cell_revealed(role: int, cell: Vector2i) -> bool:
	if role == ROLE_DM:
		return is_dm_revealed(cell)
	return is_pp_revealed(cell)


func reveal_count(role: int) -> int:
	return dm_private.size() if role == ROLE_DM else pp_shared.size()


func snapshot_for_role(role: int) -> PackedInt32Array:
	return snapshot_dm() if role == ROLE_DM else snapshot_pp()


func apply_snapshot(role: int, packed: PackedInt32Array) -> void:
	if role == ROLE_DM:
		dm_private.clear()
		decode_cells(packed, dm_private)
		reveal_changed.emit("dm")
	else:
		pp_shared.clear()
		decode_cells(packed, pp_shared)
		reveal_changed.emit("pp")


func role_for_peer(peer_id: int) -> int:
	return ROLE_DM if _is_dm_peer(peer_id) else ROLE_PP

