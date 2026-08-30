class_name IrsBuilding extends Building

@export var file_range: float = 64.0

func _enter_tree() -> void:
	super._enter_tree()
	add_to_group("irs")

func in_file_range(player: Node2D) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	if is_ghost or not is_operating():
		return false
	return player.global_position.distance_to(factory_origin()) <= file_range

func can_prompt_file(player: Node2D) -> bool:
	if not in_file_range(player):
		return false
	var player_id: int = 0
	if player.has_method("get_multiplayer_authority"):
		player_id = int(player.get_multiplayer_authority())
	if player_id <= 0 and player.name.is_valid_int():
		player_id = int(player.name)
	return PlayerManager.carried_count(player_id, PlayerManager.TAX_FORM_ITEM) >= 1

func try_file_tax(player_id: int) -> bool:
	if not multiplayer.is_server():
		return false
	if is_ghost or not is_operating():
		return false
	var player_node: Node = PlayerManager.get_player_node_by_id(player_id)
	if player_node == null or not (player_node is Node2D):
		return false
	if not in_file_range(player_node as Node2D):
		return false
	if not PlayerManager.has_resources(player_id, PlayerManager.TAX_FORM_ITEM, 1):
		return false
	PlayerManager.consume_resources(player_id, PlayerManager.TAX_FORM_ITEM, 1)
	PlayerManager.update_reality_level(PlayerManager.tax_file_rl)
	return true
