class_name IrsBuilding extends Building

@export var file_range: float = 64.0

func _enter_tree() -> void:
	super._enter_tree()
	add_to_group("irs")

func _ready() -> void:
	if _is_world_building() and is_ghost:
		enable()

func _is_world_building() -> bool:
	if str(name) == "ghost":
		return false
	var parent := get_parent()
	return parent != null and parent.is_in_group("building_root")

func is_fileable() -> bool:
	if str(name) == "ghost":
		return false
	if _is_world_building():
		return true
	return (not is_ghost) and is_operating()

func needs_tax_form() -> bool:
	return is_fileable()

func in_file_range(player: Node2D) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	if not is_fileable():
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
	if not PlayerManager.tax_form_path_in_bag(player_id).is_empty():
		return true
	if player.is_inside_tree() and player.multiplayer != null:
		return not PlayerManager.tax_form_path_in_bag(int(player.multiplayer.get_unique_id())).is_empty()
	return false

func try_file_tax(player_id: int, player_body: Node2D = null) -> bool:
	if not multiplayer.is_server():
		return false
	if not is_fileable():
		return false
	var player_node: Node2D = player_body
	if player_node == null:
		var found: Node = PlayerManager.get_player_node_by_id(player_id)
		if found is Node2D:
			player_node = found as Node2D
	if player_node == null or not is_instance_valid(player_node):
		return false
	if not in_file_range(player_node):
		return false
	var payer: int = 0
	var tax_path := ""
	for id in _candidate_ids(player_id, player_node):
		tax_path = PlayerManager.tax_form_path_in_bag(id)
		if not tax_path.is_empty():
			payer = id
			break
	if payer == 0 or tax_path.is_empty():
		return false
	PlayerManager.consume_resources(payer, tax_path, 1)
	PlayerManager.update_reality_level(PlayerManager.tax_file_rl)
	return true

func _candidate_ids(player_id: int, player_node: Node) -> Array[int]:
	var ids: Array[int] = []
	if player_id > 0:
		ids.append(player_id)
	if player_node != null:
		var auth: int = int(player_node.get_multiplayer_authority())
		if auth > 0 and auth not in ids:
			ids.append(auth)
		if player_node.name.is_valid_int():
			var named_id: int = int(player_node.name)
			if named_id > 0 and named_id not in ids:
				ids.append(named_id)
	return ids
