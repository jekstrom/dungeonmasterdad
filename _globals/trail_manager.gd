extends Node

@export var shadow_zone_seconds_max: float = 60
var shadow_zone_seconds: float = 0

var players: Array[Node] = []
var shadows: Dictionary = {}
var shadow_mode_active = false

var snake_trail_container: SnakeTrailContainer
const DEFAULT_TRAIL_LENGTH: int = 2
const TRAIL_SPACING: float = 20.0

func _ready() -> void:
	shadow_mode_active = false
	SignalBus.on_dm_unlock.connect(_on_dm_unlock)
	SignalBus.on_dm_lock.connect(_on_dm_lock)
	SignalBus.player_registered.connect(_on_player_registered)
	SignalBus.player_unregistered.connect(_on_player_registered)
	SignalBus.on_item_pickup.connect(_on_item_pickup)
	call_deferred("_refresh_players")

func _ensure_trail_container() -> SnakeTrailContainer:
	if snake_trail_container and is_instance_valid(snake_trail_container):
		return snake_trail_container
	var scene: Node = get_tree().current_scene
	if scene:
		snake_trail_container = scene.find_child("SnakeTrailContainer", true, false) as SnakeTrailContainer
	return snake_trail_container

func _refresh_players() -> void:
	players = []
	var tree := get_tree()
	if tree:
		for node in tree.get_nodes_in_group("players"):
			players.append(node)

func _on_player_registered(_player_id: int, _player_name: String = "") -> void:
	_refresh_players()
	if not shadows.has(_player_id):
		shadows[_player_id] = []
	if shadow_mode_active:
		var player_node := get_player_by_id(_player_id)
		if player_node:
			_seed_trail_for_player(player_node)

func _on_item_pickup(_player_id: int) -> void:
	if not Lobby.is_network_server():
		return
	if not shadow_mode_active:
		return
	var player_node := get_player_by_id(_player_id)
	if player_node:
		_append_trail_segment(player_node, false)

func _physics_process(_delta: float) -> void:
	pass

func _process(_delta: float) -> void:
	if not Lobby.is_network_server():
		return
	if not shadow_mode_active:
		return

	if shadow_zone_seconds > shadow_zone_seconds_max:
		DmUnlocks.lock("shadow_zone")
		return
	shadow_zone_seconds += _delta

	if _ensure_trail_container() == null:
		return
	_refresh_players()

	for player_node in players:
		var player_id = int(player_node.name)
		if not shadows.has(player_id) or shadows[player_id].is_empty():
			continue
		if player_node.position.distance_to(shadows[player_id][0].position) > TRAIL_SPACING:
			var popped_data = shadows[player_id].pop_back()
			var last_shadow = _find_trail_node(player_id, str(popped_data.id))
			if last_shadow:
				last_shadow.call_deferred("queue_free")
			var new_trail_data: Dictionary = {
				"id": generate_uuid_v4(),
				"position": player_node.position,
				"player_id": player_id,
				"player_name": player_node.name,
				"enabled": false,
			}
			shadows[player_id].push_front(new_trail_data)
			SignalBus.shadow_increased.emit(new_trail_data)
			if shadows[player_id].size() > 2:
				shadows[player_id][2].enabled = true
				var next_shadow = _find_trail_node(player_id, str(shadows[player_id][2].id))
				if next_shadow:
					next_shadow.enabled = true

func _on_dm_unlock(unlock_name: String) -> void:
	if Lobby.is_network_server() and unlock_name == "shadow_zone":
		shadow_mode_active = true
		shadow_zone_seconds = 0
		_ensure_trail_container()
		_refresh_players()
		for player_node in players:
			_seed_trail_for_player(player_node)

func _seed_trail_for_player(player_node: Node) -> void:
	if player_node == null or not is_instance_valid(player_node):
		return
	var player_id: int = int(player_node.name)
	if is_player_dm(player_id):
		return
	if not shadows.has(player_id):
		shadows[player_id] = []
	var length: int = DEFAULT_TRAIL_LENGTH
	if "num_shadows" in player_node and int(player_node.num_shadows) > 0:
		length = int(player_node.num_shadows)
	var facing: Vector2 = Vector2.DOWN
	if "prev_direction" in player_node and player_node.prev_direction != Vector2.ZERO:
		facing = player_node.prev_direction.normalized()
	elif "cardinal_direction" in player_node and player_node.cardinal_direction != Vector2.ZERO:
		facing = player_node.cardinal_direction.normalized()
	while shadows[player_id].size() < length:
		var index: int = shadows[player_id].size()
		var pos: Vector2 = player_node.position - facing * TRAIL_SPACING * float(index)
		_append_trail_segment(player_node, index >= 2, pos)

func _append_trail_segment(player_node: Node, enabled: bool, pos: Variant = null) -> void:
	var player_id: int = int(player_node.name)
	if not shadows.has(player_id):
		shadows[player_id] = []
	var spawn_pos: Vector2 = player_node.position
	if pos is Vector2:
		spawn_pos = pos
	var trail_data: Dictionary = {
		"id": generate_uuid_v4(),
		"position": spawn_pos,
		"player_id": player_id,
		"player_name": player_node.name,
		"enabled": enabled,
	}
	shadows[player_id].push_back(trail_data)
	SignalBus.shadow_increased.emit(trail_data)

func _on_dm_lock(unlock_name: String) -> void:
	if Lobby.is_network_server() and unlock_name == "shadow_zone":
		shadow_mode_active = false
		cleanup_all_players_trails()

func get_player_by_id(pid: int) -> Node:
	for player_node in players:
		if player_node.name.is_valid_int() and int(player_node.name) == pid:
			return player_node
	return null

func is_player_dm(pid: int) -> bool:
	return pid == 1

func is_trail_collision_body(collision_body: Node) -> bool:
	return collision_body is StaticBody2D and collision_body.name.begins_with("trail_collision_")

func get_trail_owner_from_collision_body(collision_body: StaticBody2D) -> int:
	if collision_body and collision_body.has_meta("player_id"):
		return collision_body.get_meta("player_id")
	return -1

func generate_uuid_v4() -> String:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var hex = "0123456789abcdef"
	var result = ""
	for i in range(16):
		result += hex[rng.randi_range(0, 15)]
	return result

func trail_node_name(player_id: int, segment_id: String) -> String:
	return ("trail_%s_%s" % [str(player_id), segment_id]).validate_node_name()

func _find_trail_node(player_id: int, segment_id: String) -> Node:
	var container := _ensure_trail_container()
	if container == null:
		return null
	return container.get_node_or_null(trail_node_name(player_id, segment_id))

func should_ignore_self_trail(player_id: int, segment_id: String) -> bool:
	if not shadows.has(player_id) or shadows[player_id].is_empty():
		return true
	var trail: Array = shadows[player_id]
	if trail.size() > 0 and str(trail[0].id) == segment_id:
		return true
	if trail.size() > 1 and str(trail[1].id) == segment_id:
		return true
	return false

func check_trail_collisions(player: Player) -> bool:
	var collider = null
	for i in player.get_slide_collision_count():
		var collision = player.get_slide_collision(i)
		if !collision:
			continue
		collider = collision.get_collider()
		if collider:
			break

	if !collider:
		return false

	if is_trail_collision_body(collider):
		var trail_owner_id = get_trail_owner_from_collision_body(collider)
		if trail_owner_id == -1 or is_player_dm(trail_owner_id):
			return false

		if trail_owner_id == int(player.name):
			var segment_id = ""
			if collider.has_meta("id"):
				segment_id = collider.get_meta("id")
			if should_ignore_self_trail(trail_owner_id, segment_id):
				return false

		return true

	return false

func handle_trail_death(pid: int, death_position: Vector2) -> void:
	if not Lobby.is_network_server():
		return
	DeathSystem.request_player_death(pid, death_position)
	cleanup_player_trail(pid)

func cleanup_all_players_trails() -> void:
	for player in players:
		var player_id: int = int(player.name)
		cleanup_player_trail(player_id)

func cleanup_player_trail(player_id: int) -> void:
	if not Lobby.is_network_server():
		return
	if not shadows.has(player_id):
		return
	for shadow in shadows[player_id]:
		var shadow_node = _find_trail_node(player_id, str(shadow.id))
		if !shadow_node:
			continue
		shadow_node.call_deferred("queue_free")
	shadows[player_id] = []
