extends Node2D

var damage_numbers_scene: PackedScene = preload("res://spells/damage_number.tscn")

# Handle global level-based events such as projectiles

func _ready() -> void:
	if !multiplayer.is_server(): return
	if !SignalBus.on_explosion.is_connected(on_explosion):
		SignalBus.on_explosion.connect(on_explosion)
		
func on_explosion(proj_position: Vector2, explosion_data: Dictionary) -> void:
	if !multiplayer.is_server(): return
	explosion_data["position"] = proj_position
	handle_explosion(explosion_data)

func handle_explosion(explosion_data: Dictionary) -> void:
	if !multiplayer.is_server(): return
	for player_id in PlayerManager.players_data.keys():
		var player_node = get_node_or_null(str(player_id)) as Node2D
		if !player_node or !player_node is Player: continue
		if player_node.position.distance_to(explosion_data.position) <= explosion_data.radius:
			print("player ", player_id, " hit!")
			if explosion_data.damage:
				show_damage_number.rpc(explosion_data.damage, player_node.global_position, player_node.sync_color)
				PlayerManager.update_reality_level(-explosion_data.damage)

@rpc("any_peer", "call_local", "reliable")
func show_damage_number(damage: int, spawn_pos: Vector2, color: Color):
	var dmg_numbers = damage_numbers_scene.instantiate() as Node2D
	dmg_numbers.global_position = spawn_pos
	dmg_numbers.get_node("DamageNumber").text = str(damage)
	dmg_numbers.get_node("DamageNumber").self_modulate = color
	get_tree().current_scene.add_child(dmg_numbers)
