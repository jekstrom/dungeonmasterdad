extends Node

#const __DM__ = preload("uid://e1aypo2ysyyc")
#const INVENTORY_DATA: InventoryData = preload("res://gui/pause_menu/inventory/player_inventory.tres")

#signal interact_pressed

var player: Player
var player_spawned: bool = false

@export var max_inv_slots: int = 8

# Structure: { peer_id: { "inventory": { "item_id": quantity } } }
var players_data = {}

func _ready() -> void:
	add_player_instance()
	await get_tree().create_timer(0.2).timeout
	player_spawned = true
	
func register_player(id: int):
	if not multiplayer.is_server(): return
	
	# Initialize empty data for new player
	players_data[id] = {
		"inventory": {} # Empty dictionary: "id": amount
	}
	print("Player ", id, " registered in Global Manager.")
	
func unregister_player(id: int):
	if multiplayer.is_server() and players_data.has(id):
		# Optional: Save to disk here before erasing
		players_data.erase(id)
		
func add_item_to_inventory(player_id: int, item_data: ItemData, amount: int = 1):
	if not multiplayer.is_server(): return
	if !players_data.has(player_id): return
	
	var item_id = item_data.resource_path
	
	var inventory = players_data[player_id]["inventory"]

	if inventory.keys().size() < max_inv_slots:
		if inventory.has(item_id):
			inventory[item_id] += amount
		else:
			inventory[item_id] = amount
		# Sync the entire inventory dictionary to the specific client
		update_client_inventory.rpc_id(player_id, inventory)

@rpc("authority", "reliable")
func update_client_inventory(new_items: Dictionary):
	var display_list = []
	for id in new_items.keys():
		var resource = ItemDatabase.get_item(id)
		if resource:
			var quantity = new_items[id]
			display_list.append({"data": resource, "quantity": quantity})
	
	SignalBus.emit_signal("inventory_updated", display_list)

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
