class_name Skeleton extends Enemy

func _ready() -> void:
	max_hp = 5
	hp = 5
	super._ready()
	add_to_group("skeletons")
	var hurtbox := get_node_or_null("Hurtbox")
	if hurtbox is Area2D:
		(hurtbox as Area2D).monitoring = false

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not multiplayer.is_server():
		return
	if _dying:
		return
	if RealityClaim.is_world_claimed(get_tree(), global_position):
		die()
		return
	if not _is_in_dungeon():
		die()

func _is_in_dungeon() -> bool:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager == null or not manager.has_method("is_world_position_in_dungeon"):
		return true
	return bool(manager.is_world_position_in_dungeon(global_position))
