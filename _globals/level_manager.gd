extends Node


func _ready() -> void:
	SignalBus.on_explosion.connect(on_explosion)
	
func on_explosion(position: Vector2, explosion_data: Dictionary) -> void:
	explosion_data["position"] = position
	handle_explosion.rpc_id(1, explosion_data)

@rpc("any_peer", "call_remote", "reliable")
func handle_explosion(explosion_data: Dictionary) -> void:
	if !multiplayer.is_server(): return
	print("checking if any players were hit...")

	for player_id in PlayerManager.players_data.keys():
		print("player_id ", player_id)
		var player_node = get_node_or_null(str(player_id)) as Node2D
		if !player_node or !player_node is Player: continue
		print("found player ", player_node.name)
		print("player pos: ", player_node.position, " fireball pos",explosion_data.position)
		if player_node.position.distance_to(explosion_data.position) <= explosion_data.radius:
			print("player ", player_id, " hit!")
			PlayerManager.update_reality_level(-explosion_data.damage)
			
