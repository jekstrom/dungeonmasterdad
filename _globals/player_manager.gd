# PlayerManager
extends Node

#const __DM__ = preload("uid://e1aypo2ysyyc")
#const INVENTORY_DATA: InventoryData = preload("res://gui/pause_menu/inventory/player_inventory.tres")

#signal interact_pressed

var player: Player
var player_spawned: bool = false

@export var max_inv_slots: int = 8
@export var reality_level: int = 0
@export var max_smoke_amt: int = 5
@export var max_paper_amt: int = 99
@export var smoke_amt: int = 0
signal reality_level_changed(new_reality_level: int)
signal smoke_amt_changed(new_smoke_amt: int)

# Structure: { peer_id: { "inventory": { "item_id": quantity } } }
var players_data = {}
var local_inventory: Dictionary = {}

func _ready() -> void:
	add_player_instance()
	await get_tree().create_timer(0.2).timeout
	player_spawned = true
	
func register_player(id: int, player_name: String):
	if not multiplayer.is_server(): return
	
	if !player_name or player_name.is_empty():
		player_name = "Paper Pusher"
	
	# Initialize empty data for new player
	players_data[id] = {
		"inventory": {},
		"name": player_name,
	}
	print("Player ", id, " registered in Global Manager with name ", player_name)
	SignalBus.player_registered.emit(id, player_name)

func unregister_player(id: int):
	if multiplayer.is_server() and players_data.has(id):
		print("Unregistering player ", id, " - cleaning up all data")
		
		# Clean up any trails for disconnecting player
		TrailManager.cleanup_player_trail(id)
		
		# Clean up server trail tracking if in snake mode
		var players = get_tree().get_nodes_in_group("players")
		for player_node in players:
			if player_node.name.is_valid_int() and int(player_node.name) == id:
				var state_machine = player_node.get_node_or_null("PlayerStateMachine")
				if state_machine and state_machine.current_state and state_machine.current_state.name == "snake":
					# Player was in snake mode, clean up server tracking
					if player_node.get_script() and player_node.get_script().has_method("stop_server_trail_tracking"):
						var snake_state = state_machine.current_state
						if snake_state.has_method("stop_server_trail_tracking"):
							snake_state.stop_server_trail_tracking(id)
		
		# Optional: Save to disk here before erasing
		players_data.erase(id)
		SignalBus.player_unregistered.emit(id)
		print("Player ", id, " fully unregistered and cleaned up")
		
func add_item_to_inventory(player_id: int, item_data: ItemData, amount: int = 1) -> bool:
	if not multiplayer.is_server():
		return false
	if item_data == null:
		return false
	if !players_data.has(player_id):
		return false

	var item_id = item_data.resource_path
	var inventory = players_data[player_id]["inventory"]

	if inventory.has(item_id):
		inventory[item_id] += amount
		_push_inventory(player_id, inventory)
		return true
	if inventory.keys().size() < max_inv_slots:
		inventory[item_id] = amount
		_push_inventory(player_id, inventory)
		return true
	return false

func grant_item_or_drop(player_id: int, item_data: ItemData, amount: int, drop_position: Vector2) -> void:
	if not multiplayer.is_server():
		return
	if item_data == null:
		return
	if add_item_to_inventory(player_id, item_data, amount):
		return
	for _i in range(maxi(1, amount)):
		SignalBus.on_item_drop.emit({
			"item_type": item_data.resource_path,
			"position": drop_position,
		})

func _push_inventory(player_id: int, inventory: Dictionary) -> void:
	update_client_inventory.rpc_id(player_id, inventory)
	SignalBus.on_item_pickup.emit(player_id)

func get_item_count(player_id: int, item_id: String) -> int:
	if !players_data.has(player_id):
		return 0
	var inventory = players_data[player_id]["inventory"]
	if !inventory.has(item_id):
		return 0
	return int(inventory[item_id])

func carried_count(player_id: int, item_id: String) -> int:
	var from_data: int = get_item_count(player_id, item_id)
	var from_local: int = 0
	if local_inventory.has(item_id):
		from_local = int(local_inventory[item_id])
	return maxi(from_data, from_local)

@rpc("authority", "call_local", "reliable")
func update_client_inventory(new_items: Dictionary):
	local_inventory = new_items.duplicate()
	var display_list = []
	for id in new_items.keys():
		var resource = ItemDatabase.get_item(id)
		if resource:
			var quantity = new_items[id]
			display_list.append({"data": resource, "quantity": quantity})
	
	SignalBus.emit_signal("inventory_updated", display_list)

@rpc("authority", "reliable")
func has_resources(player_id, resource_id, cost) -> bool:
	if not multiplayer.is_server(): 
		return false
	if !players_data.has(player_id): 
		return false
	
	var inventory = players_data[player_id]["inventory"]
	if !inventory.has(resource_id):
		return false
	var x = inventory[resource_id] >= cost
	print("player has resources? ", x)
	return x
	
@rpc("authority", "reliable")
func consume_resources(player_id, resource_id, cost) -> void:
	if not multiplayer.is_server(): 
		return
	if !players_data.has(player_id): 
		return
			
	var inventory = players_data[player_id]["inventory"]
	if !inventory.has(resource_id):
		return
	inventory[resource_id] -= cost
	if inventory[resource_id] <= 0:
		inventory.erase(resource_id)
	update_client_inventory.rpc_id(player_id, inventory)

func add_player_instance() -> void:
	pass
	#dm = __DM__.instantiate()
	#add_child(player)

func set_player_pos(new_pos: Vector2) -> void:
	player.global_position = new_pos

func set_player_health(hp: int, max_hp: int) -> void:
	player.max_hp = max_hp
	player.hitpoints = hp
	#DmHud.update_hp(hp, max_hp)

func set_as_parent(p: Node2D) -> void:
	if player.get_parent():
		player.get_parent().remove_child(player)
	p.add_child(player)

func unparent_player(p: Node2D) -> void:
	p.remove_child(player)

func update_reality_level(level_inc: int) -> void:
	if multiplayer.is_server():
		reality_level += level_inc
		request_reality_level_increase.rpc(reality_level)
		
func add_smoke(smoke_inc: int) -> void:
	if !multiplayer.is_server(): return
	if smoke_amt >= max_smoke_amt: return
	
	smoke_amt += smoke_inc
	request_smoke_value_change.rpc(smoke_amt)

func use_smoke(smoke_dec: int) -> bool:
	if !multiplayer.is_server(): return false
	if smoke_dec > smoke_amt: return false
	
	smoke_amt -= smoke_dec
	request_smoke_value_change.rpc(smoke_amt)
	return true

@rpc("authority", "call_local", "reliable")
func request_reality_level_increase(new_reality_level: int):
		reality_level = new_reality_level
		reality_level_changed.emit(new_reality_level)
		
@rpc("authority", "call_local", "reliable")
func request_smoke_value_change(new_smoke_amt: int):
		smoke_amt = new_smoke_amt
		smoke_amt_changed.emit(new_smoke_amt)

# Respawn a player at the starting location with a delay
func respawn_player(player_id: int) -> void:
	if not multiplayer.is_server():
		print("WARNING: respawn_player called on non-server")
		return
	
	# Get the player node
	var player_node = get_player_node_by_id(player_id)
	if not player_node:
		print("ERROR: Could not find player node for respawn: ", player_id)
		return
	
	print("Scheduling respawn for player ", player_id, " in 2 seconds...")
	
	# Add a 2-second delay before respawn for dramatic effect
	await get_tree().create_timer(2.0).timeout
	
	# Double-check player still exists after delay
	player_node = get_player_node_by_id(player_id)
	if not player_node:
		print("ERROR: Player node disappeared during respawn delay: ", player_id)
		return
	
	# Get respawn position (near Reality Zone center)
	var respawn_position = get_respawn_position()
	
	print("Respawning player ", player_id, " at ", respawn_position)
	
	player_node.global_position = respawn_position
	var level: Node = get_tree().get_first_node_in_group("level_manager")
	if level and level.has_method("enforce_body_interior"):
		level.enforce_body_interior(player_node)
	
	# Reset player health
	player_node.hitpoints = player_node.max_hp
	
	# Reset player state to idle (exit snake mode if active)
	if player_node.has_method("force_idle_state"):
		player_node.force_idle_state()
	elif player_node.has_node("PlayerStateMachine"):
		var state_machine = player_node.get_node("PlayerStateMachine")
		if state_machine.has_method("force_change_state"):
			var idle_state = state_machine.get_node_or_null("idle")
			if idle_state:
				state_machine.force_change_state(idle_state)
	
	# Notify all clients of the respawn
	notify_player_respawned.rpc(player_id, respawn_position)
	
	# Emit signal for other systems
	SignalBus.player_respawned.emit(player_id, respawn_position)

# Get a player node by ID (similar to snake state function but in manager)
func get_player_node_by_id(pid: int) -> Node:
	var world_node = get_tree().current_scene
	if not world_node:
		return null
	
	# Try direct name lookup first (most common case)
	var player_node = world_node.get_node_or_null(str(pid))
	if player_node:
		return player_node
	
	# Fallback to searching all players in group
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		if p.name.is_valid_int() and int(p.name) == pid:
			return p
		elif p.has_method("get_player_id") and p.get_player_id() == pid:
			return p
		elif "player_id" in p and p.player_id == pid:
			return p
	
	return null

func get_respawn_position() -> Vector2:
	var level: Node = get_tree().get_first_node_in_group("level_manager")
	if level and level.has_method("has_map_bounds") and level.has_map_bounds() and level.has_method("take_west_spawn_world"):
		return level.take_west_spawn_world()
	var chosen := Vector2(183, 74)
	var world_node = get_tree().current_scene
	if world_node:
		var reality_zone = world_node.get_node_or_null("RealityZone")
		if reality_zone:
			chosen = reality_zone.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	if level and level.has_method("has_map_bounds") and level.has_map_bounds() and level.has_method("clamp_world_to_interior"):
		return level.clamp_world_to_interior(chosen)
	return chosen

@rpc("authority", "call_local", "reliable")
func notify_player_respawned(player_id: int, respawn_position: Vector2) -> void:
	print("Player ", player_id, " respawned at ", respawn_position)

# Helper function to recursively find MultiplayerSpawner in the scene tree
func _find_multiplayer_spawner_recursive(node: Node) -> Node:
	# Check if current node is a MultiplayerSpawner with spawn_pickup_item method
	if node.get_class() == "MultiplayerSpawner" and node.has_method("spawn_pickup_item"):
		return node
	
	# Search children recursively
	for child in node.get_children():
		var result = _find_multiplayer_spawner_recursive(child)
		if result:
			return result
	
	return null
