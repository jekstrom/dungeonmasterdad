extends Node

func _ready() -> void:
	var player: Player = load("res://player/player.tscn").instantiate() as Player
	var wall: WallDoodad = load("res://level/wall.tscn").instantiate() as WallDoodad
	var tree: TreeDoodad = load("res://doodads/tree.tscn").instantiate() as TreeDoodad
	var mine: MineDoodad = load("res://doodads/mine.tscn").instantiate() as MineDoodad
	add_child(player)
	add_child(wall)
	add_child(tree)
	add_child(mine)
	await get_tree().process_frame

	if player.z_index != DungeonConstants.WALL_Z_INDEX:
		_fail("player z_index must match walls, got %d" % player.z_index)
		return
	if wall.z_index != DungeonConstants.WALL_Z_INDEX:
		_fail("wall z_index must be WALL_Z_INDEX")
		return
	if tree.z_index != DungeonConstants.WALL_Z_INDEX:
		_fail("tree z_index must match walls")
		return
	if mine.z_index != DungeonConstants.WALL_Z_INDEX:
		_fail("mine z_index must match walls")
		return
	var tree_sprite: Sprite2D = tree.get_node_or_null("Sprite2D") as Sprite2D
	if tree_sprite == null or tree_sprite.position != Vector2.ZERO or tree_sprite.offset.y >= 0.0:
		_fail("tree sprite must sort at the trunk with a negative offset")
		return
	var wall_sprite: Sprite2D = wall.get_node_or_null("Sprite2D") as Sprite2D
	if wall_sprite == null or wall_sprite.position != Vector2.ZERO or wall_sprite.offset.y >= 0.0:
		_fail("wall sprite must use south-foot offset, offset=%s" % wall_sprite.offset)
		return
	print("ysort actors test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
