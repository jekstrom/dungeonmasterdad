class_name OfficeMaxBuilding extends Building

const METAL_ITEM := "res://pickups/metal.tres"
const RUINED_SPRITE := "res://sprites/office_max_rubble.png"
const LIVE_SPRITE := "res://sprites/office_max.png"

@export var restock_range: float = 64.0

func _enter_tree() -> void:
	super._enter_tree()
	add_to_group("office_max")

func _ready() -> void:
	super._ready()
	if _is_world_building() and is_ghost and not destroyed:
		enable()

func _is_world_building() -> bool:
	if str(name) == "ghost":
		return false
	var parent := get_parent()
	return parent != null and parent.is_in_group("building_root")

func is_restockable() -> bool:
	if str(name) == "ghost":
		return false
	if destroyed:
		return false
	if _is_world_building():
		return true
	return (not is_ghost) and is_operating()

func in_restock_range(player: Node2D) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	if not is_restockable():
		return false
	return player.global_position.distance_to(factory_origin()) <= restock_range

func can_prompt_restock(player: Node2D) -> bool:
	# US-010 T003 (James live): prompt when in range and mag not full.
	# Optionally has >=1 iron; try_restock enforces the 1-iron cost.
	if not in_restock_range(player):
		return false
	if not ("staple_count" in player) or not ("staple_magazine_max" in player):
		return false
	var count: int = int(player.staple_count)
	var mag_max: int = int(player.staple_magazine_max)
	if count >= mag_max:
		return false
	return true

func try_restock_staples(player_id: int, player_body: Node2D = null) -> bool:
	# US-010 T003 (James live): each successful interact spends exactly 1 iron
	# and adds up to 10 staples (partial top-up still costs 1). Never fill-to-max
	# with ceil(needed/10) multi-iron spend in one press (old behavior).
	if not multiplayer.is_server():
		return false
	if not is_restockable():
		return false
	var player_node: Node2D = player_body
	if player_node == null:
		var found: Node = PlayerManager.get_player_node_by_id(player_id)
		if found is Node2D:
			player_node = found as Node2D
	if player_node == null or not is_instance_valid(player_node):
		return false
	if not in_restock_range(player_node):
		return false
	if not ("staple_count" in player_node) or not ("staple_magazine_max" in player_node):
		return false
	var count: int = int(player_node.staple_count)
	var mag_max: int = int(player_node.staple_magazine_max)
	var needed: int = mag_max - count
	if needed <= 0:
		return false
	var add: int = mini(10, needed)
	var iron_cost: int = 1
	var payer: int = 0
	for id in _candidate_ids(player_id, player_node):
		if PlayerManager.has_resources(id, METAL_ITEM, iron_cost):
			payer = id
			break
	if payer == 0:
		return false
	PlayerManager.consume_resources(payer, METAL_ITEM, iron_cost)
	player_node.staple_count = mini(count + add, mag_max)
	if player_node.has_method("_replicate_staple_count"):
		player_node._replicate_staple_count()
	elif player_node.has_method("_refresh_staple_hud"):
		player_node._refresh_staple_hud()
	return true

func apply_ruined_placeholder_visuals() -> void:
	# Used by building.gd rubble path; safe if ruined art is missing.
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	var ruined_path := RUINED_SPRITE
	if not ResourceLoader.exists(ruined_path):
		ruined_path = "res://sprites/office_max_ruined.png"
	if ResourceLoader.exists(ruined_path):
		sprite.texture = load(ruined_path)
		sprite.modulate = Color(1, 1, 1, 1)
	else:
		# Art will swap when rubble/ruined sheet lands; darken live sprite.
		if sprite.texture == null and ResourceLoader.exists(LIVE_SPRITE):
			sprite.texture = load(LIVE_SPRITE)
		sprite.modulate = Color(0.35, 0.35, 0.35, 1.0)
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.frame = 0

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
