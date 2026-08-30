extends Node

func _ready() -> void:
	var mine: MineDoodad = load("res://doodads/mine.tscn").instantiate() as MineDoodad
	if mine == null:
		_fail("US-007 T002: mine.tscn must instance as MineDoodad")
		return
	add_child(mine)
	await get_tree().process_frame
	var hit: Hitbox = mine.get_node_or_null("Hitbox") as Hitbox
	if hit == null:
		_fail("US-007 T002: mine must have a Hitbox")
		return
	if hit.collision_layer != 8:
		_fail("US-007 T002: harvest Hitbox must be layer 8, got %d" % hit.collision_layer)
		return
	var body: StaticBody2D = mine.get_node_or_null("StaticBody2D") as StaticBody2D
	if body == null or body.collision_layer != 16:
		_fail("US-007 T002: mine StaticBody2D must be doodad layer 16")
		return
	if mine.sprite_2d == null or mine.sprite_2d.texture == null:
		_fail("US-007 T002: mine must show active texture")
		return
	if str(mine.sprite_2d.texture.resource_path).find("mine_active") == -1:
		_fail("US-007 T002: default sprite must be mine_active.png")
		return
	if load("res://sprites/mine_depleted.png") == null:
		_fail("US-007 T002: mine_depleted.png must exist")
		return
	print("US-007 T002 mine doodad test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
