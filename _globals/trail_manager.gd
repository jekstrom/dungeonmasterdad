#TrailManager
extends Node

var players: Array[Node] = []
var shadows: Dictionary = {}
var shadow_mode_active = false

var snake_trail_container: SnakeTrailContainer

func _enter_tree() -> void:
	if !snake_trail_container:
		snake_trail_container = get_tree().current_scene.find_child("SnakeTrailContainer")

func _ready() -> void:
	# Connect to shadow zone unlock signal
	shadow_mode_active = false
	SignalBus.on_dm_unlock.connect(_on_dm_unlock)
	SignalBus.player_registered.connect(_on_player_registered)
	SignalBus.player_unregistered.connect(_on_player_registered)
	SignalBus.on_item_pickup.connect(_on_item_pickup)
	players = get_tree().get_nodes_in_group("players")
	
func _on_player_registered(_player_id: int, _player_name: String = "") -> void:
	players = get_tree().get_nodes_in_group("players")
	shadows[_player_id] = []
	
func _on_item_pickup(_player_id: int) -> void:
	if !multiplayer.is_server(): return
	players = get_tree().get_nodes_in_group("players")
	for player_node in players:
		var player_id = int(player_node.name) 
		if player_id == _player_id:
			var trail_data: Dictionary = {
				"id": generate_uuid_v4(), 
				"position": player_node.position, 
				"player_id": player_id, 
				"player_name": player_node.name,
				"enabled": false,
			}
			shadows[_player_id].push_back(trail_data)
			SignalBus.shadow_increased.emit(trail_data)

func _physics_process(_delta: float) -> void:
	pass

func _process(_delta: float) -> void:
	if !multiplayer.is_server(): return
	if !shadow_mode_active: return

	if !snake_trail_container:
		print("TrailManager: FATAL - no snake trail container found")
		assert(false, "no snake trail container found")
		return
	
	for player_node in players:
		var player_id = int(player_node.name)
		if shadows.size() > 0 and shadows[player_id].size() > 0 and player_node.position.distance_to(shadows[player_id][0].position) > 20:
			var popped_data = shadows[player_id].pop_back()
			var last_shadow = snake_trail_container.find_child("trail_" + player_node.name + "_" + popped_data.id, false, false)
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
					var next_shadow = snake_trail_container.find_child("trail_" + player_node.name + "_" + shadows[player_id][2].id, false, false)
					if next_shadow:
						next_shadow.enabled = true
			else:
				print("trail_" + player_node.name + "_" + popped_data.id + " not found")
	pass

func _on_dm_unlock(unlock_name: String) -> void:
	if multiplayer.is_server() and unlock_name == "shadow_zone":
		print("TrailManager: Shadow zone unlocked - creating trail containers for all players")
		shadow_mode_active = true

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
	
	var uuid = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
	var hex = "0123456789abcdef"
	
	var result = ""
	for i in range(uuid.length()):
		var c = uuid[i]
		if c == "x":
			result += hex[rng.randi_range(0, 15)]
		elif c == "y":
			# y must be 8, 9, a, or b
			result += hex[rng.randi_range(8, 11)]
		else:
			result += c
			
	return result

func check_trail_collisions(player: Player) -> bool:
	var collider = null
	for i in player.get_slide_collision_count():
		var collision = player.get_slide_collision(i)
		if !collision:  continue
		collider = collision.get_collider()
		if collider: break
	
	if !collider: return false
	
	if is_trail_collision_body(collider):
		var trail_owner_id = get_trail_owner_from_collision_body(collider)
		if trail_owner_id == -1 or is_player_dm(trail_owner_id): return false
		
		if trail_owner_id == int(player.name):
			var segment_id = ""
			if collider.has_meta("id"):
				segment_id = collider.get_meta("id")
			if shadows.size() and shadows[trail_owner_id].size():
				# Ignore first 2 self-shadows for collisions
				if shadows[trail_owner_id][0].id == segment_id or shadows[trail_owner_id][1] == segment_id:
					return false
			
		return true
	
	return false

func handle_trail_death(pid: int, death_position: Vector2) -> void:
	if !multiplayer.is_server(): return
	print("💀 DEATH: Player ", pid, " died from trail collision at ", death_position)
	DeathSystem.request_player_death(pid, death_position)
	cleanup_player_trail(pid)

# Clean up trail immediately on player death (server-side)
func cleanup_player_trail(player_id: int) -> void:
	if not multiplayer.is_server(): return
	
	for shadow in shadows[player_id]:
		var shadow_node = snake_trail_container.find_child("trail_" + str(player_id) + "_*" + shadow.id, false, false)
		if !shadow_node: continue
		shadow_node.call_deferred("queue_free")
	shadows[player_id] = []
