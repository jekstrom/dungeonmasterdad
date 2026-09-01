extends Node

## US-033 host-authoritative mini-map fog.
## Two isolated sticky reveal sets: pp_shared_reveal (all PPs) and dm_reveal (DM only).
## Clients paint only from replicated state — they never invent reveals.

const ROLE_PP := 0
const ROLE_DM := 1
const VISIT_RADIUS := 3

signal pp_reveal_changed
signal dm_reveal_changed

## Vector2i -> true
var pp_shared_reveal: Dictionary = {}
var dm_reveal: Dictionary = {}

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


func _process(_delta: float) -> void:
	if not Lobby.is_network_server():
		return
	_host_tick_living_movers()


func _on_host_started(_player_name = null) -> void:
	if not Lobby.is_network_server():
		return
	reset_reveals()
	_ensure_peer_connected_hook()


func _on_map_bounds_cleared() -> void:
	reset_reveals()


func reset_reveals() -> void:
	pp_shared_reveal.clear()
	dm_reveal.clear()
	_pp_delta_pending.clear()
	_dm_delta_pending.clear()
	pp_reveal_changed.emit()
	dm_reveal_changed.emit()


func reveal_count(role: int) -> int:
	return get_reveal_set(role).size()


func get_reveal_set(role: int) -> Dictionary:
	if role == ROLE_DM:
		return dm_reveal
	return pp_shared_reveal


func is_cell_revealed(role: int, cell: Vector2i) -> bool:
	return get_reveal_set(role).has(cell)


## Host or harness: expand Chebyshev brush into the role set. Sticky.
func apply_visit_at(role: int, center: Vector2i) -> int:
	var target: Dictionary = get_reveal_set(role)
	var pending: Dictionary = _pp_delta_pending if role == ROLE_PP else _dm_delta_pending
	var added := 0
	for dy in range(-VISIT_RADIUS, VISIT_RADIUS + 1):
		for dx in range(-VISIT_RADIUS, VISIT_RADIUS + 1):
			if maxi(absi(dx), absi(dy)) > VISIT_RADIUS:
				continue
			var cell := Vector2i(center.x + dx, center.y + dy)
			if target.has(cell):
				continue
			target[cell] = true
			pending[cell] = true
			added += 1
	if added > 0:
		_emit_role(role)
		_queue_flush()
	return added


## Encode full set for late-join / harness.
func snapshot_for_role(role: int) -> PackedInt32Array:
	return _pack_cells(get_reveal_set(role))


func apply_snapshot(role: int, packed: PackedInt32Array) -> void:
	var target: Dictionary = get_reveal_set(role)
	target.clear()
	_unpack_into(packed, target)
	_emit_role(role)


func apply_delta(role: int, packed: PackedInt32Array) -> void:
	var target: Dictionary = get_reveal_set(role)
	var before: int = target.size()
	_unpack_into(packed, target)
	if target.size() != before:
		_emit_role(role)


func _host_tick_living_movers() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("players"):
		if not _actor_alive(node):
			continue
		if not (node is Node2D):
			continue
		apply_visit_at(ROLE_PP, DungeonGrid.from_world((node as Node2D).global_position))
	var dm_node: Node = null
	if DmManager.dm != null and is_instance_valid(DmManager.dm):
		dm_node = DmManager.dm
	else:
		dm_node = tree.get_first_node_in_group("dm")
	if dm_node != null and _actor_alive(dm_node) and dm_node is Node2D:
		apply_visit_at(ROLE_DM, DungeonGrid.from_world((dm_node as Node2D).global_position))


func _actor_alive(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if node.has_method("is_downed") and bool(node.call("is_downed")):
		return false
	if "hitpoints" in node and int(node.get("hitpoints")) <= 0:
		return false
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
		var packed: PackedInt32Array = _pack_cells(_pp_delta_pending)
		_pp_delta_pending.clear()
		_rpc_pp_delta.rpc(packed)
	if not _dm_delta_pending.is_empty():
		var packed_dm: PackedInt32Array = _pack_cells(_dm_delta_pending)
		_dm_delta_pending.clear()
		_send_dm_delta(packed_dm)


func _send_dm_delta(packed: PackedInt32Array) -> void:
	var dm_peer := _dm_peer_id()
	if dm_peer <= 0:
		return
	# Host may also be the DM (listen server) — local set already updated.
	if dm_peer == multiplayer.get_unique_id():
		return
	_rpc_dm_delta.rpc_id(dm_peer, packed)


func _on_peer_connected(peer_id: int) -> void:
	if not Lobby.is_network_server():
		return
	_ensure_peer_connected_hook()
	# Role may not be known yet; default PP shared snapshot. DM spawn path /
	# request_reveal_snapshot corrects with dm_reveal (AC10 / AC11).
	if _is_dm_peer(peer_id):
		_rpc_dm_snapshot.rpc_id(peer_id, snapshot_for_role(ROLE_DM))
	else:
		_rpc_pp_snapshot.rpc_id(peer_id, snapshot_for_role(ROLE_PP))


## Explicit late-join push used by harness / join handshake callers.
func send_late_join_snapshot(peer_id: int, role: int) -> void:
	if not Lobby.is_network_server():
		return
	if role == ROLE_DM:
		_rpc_dm_snapshot.rpc_id(peer_id, snapshot_for_role(ROLE_DM))
	else:
		_rpc_pp_snapshot.rpc_id(peer_id, snapshot_for_role(ROLE_PP))


## Client asks host for the role-appropriate full set (late join / first paint).
@rpc("any_peer", "reliable")
func request_reveal_snapshot(role: int) -> void:
	if not Lobby.is_network_server():
		return
	var peer_id: int = multiplayer.get_remote_sender_id()
	if peer_id <= 0:
		return
	send_late_join_snapshot(peer_id, role)


func request_snapshot_for_local_role(role: int) -> void:
	if Lobby.is_network_server():
		return
	if not multiplayer.has_multiplayer_peer():
		return
	if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return
	request_reveal_snapshot.rpc_id(1, role)


@rpc("authority", "reliable")
func _rpc_pp_delta(packed: PackedInt32Array) -> void:
	if Lobby.is_network_server():
		return
	apply_delta(ROLE_PP, packed)


@rpc("authority", "reliable")
func _rpc_dm_delta(packed: PackedInt32Array) -> void:
	if Lobby.is_network_server():
		return
	apply_delta(ROLE_DM, packed)


@rpc("authority", "reliable")
func _rpc_pp_snapshot(packed: PackedInt32Array) -> void:
	apply_snapshot(ROLE_PP, packed)


@rpc("authority", "reliable")
func _rpc_dm_snapshot(packed: PackedInt32Array) -> void:
	apply_snapshot(ROLE_DM, packed)


func _pack_cells(source: Dictionary) -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(source.size() * 2)
	var i := 0
	for cell in source.keys():
		var c: Vector2i = cell
		out[i] = c.x
		out[i + 1] = c.y
		i += 2
	return out


func _unpack_into(packed: PackedInt32Array, target: Dictionary) -> void:
	var n: int = packed.size()
	var i := 0
	while i + 1 < n:
		target[Vector2i(packed[i], packed[i + 1])] = true
		i += 2


func _emit_role(role: int) -> void:
	if role == ROLE_DM:
		dm_reveal_changed.emit()
	else:
		pp_reveal_changed.emit()


func _dm_peer_id() -> int:
	if DmManager.dm != null and is_instance_valid(DmManager.dm):
		return int(DmManager.dm.get_multiplayer_authority())
	return -1


func _is_dm_peer(peer_id: int) -> bool:
	if peer_id <= 0:
		return false
	var dm_peer := _dm_peer_id()
	if dm_peer <= 0:
		return false
	return peer_id == dm_peer


## Marker visibility helpers (FR-007) — host-known cells only.
func should_show_pp_marker(viewer_role: int, pp_cell: Vector2i) -> bool:
	if viewer_role == ROLE_PP:
		return true
	return is_cell_revealed(ROLE_DM, pp_cell)


func should_show_dm_marker(viewer_role: int, dm_cell: Vector2i) -> bool:
	if viewer_role == ROLE_DM:
		return true
	return is_cell_revealed(ROLE_PP, dm_cell)


## Chebyshev brush cell count for radius r (filled square).
static func brush_cell_count(radius: int = VISIT_RADIUS) -> int:
	var side: int = radius * 2 + 1
	return side * side
