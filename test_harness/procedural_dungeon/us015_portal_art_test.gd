extends Node

func _ready() -> void:
	var catalog := TileCatalog.new()
	if catalog.get_entrance_scene_path() != "res://level/dungeon_entrance.tscn":
		push_error("US-015: entrance path")
		get_tree().quit(1)
		return
	if catalog.get_exit_scene_path() != "res://level/dungeon_exit.tscn":
		push_error("US-015: exit path")
		get_tree().quit(1)
		return
	if not catalog.is_valid_for_role("entrance", TileCatalog.ENTRANCE_SCENE_PATH):
		push_error("US-015: entrance role")
		get_tree().quit(1)
		return
	if not catalog.is_valid_for_role("exit", TileCatalog.EXIT_SCENE_PATH):
		push_error("US-015: exit role")
		get_tree().quit(1)
		return
	if catalog.is_valid_for_role("entrance", TileCatalog.FLOOR_SCENE_PATH):
		push_error("US-015: entrance must not use floor.tscn")
		get_tree().quit(1)
		return
	if catalog.is_valid_for_role("exit", "res://level/outside_tile.tscn"):
		push_error("US-015: exit must not use outside tile")
		get_tree().quit(1)
		return
	var outside := OutsideCatalog.new()
	if not outside.is_dungeon_tile_path(TileCatalog.ENTRANCE_SCENE_PATH) or not outside.is_dungeon_tile_path(TileCatalog.EXIT_SCENE_PATH):
		push_error("US-015: portals must be dungeon catalog")
		get_tree().quit(1)
		return
	if outside.is_dungeon_tile_path(OutsideCatalog.OUTSIDE_SCENE_PATH):
		push_error("US-015: outside tile is not dungeon")
		get_tree().quit(1)
		return
	var entrance: Node2D = load(TileCatalog.ENTRANCE_SCENE_PATH).instantiate()
	var exit_tile: Node2D = load(TileCatalog.EXIT_SCENE_PATH).instantiate()
	add_child(entrance)
	add_child(exit_tile)
	await get_tree().process_frame
	var e_sprite: Sprite2D = entrance.get_node_or_null("Sprite2D")
	var x_sprite: Sprite2D = exit_tile.get_node_or_null("Sprite2D")
	if e_sprite == null or x_sprite == null:
		push_error("US-015: portal sprite missing")
		get_tree().quit(1)
		return
	if e_sprite.position != Vector2(0, -63) or x_sprite.position != Vector2(0, -63):
		push_error("US-015: portal offset must match floor.tscn")
		get_tree().quit(1)
		return
	if e_sprite.texture == null or x_sprite.texture == null:
		push_error("US-015: portal texture missing")
		get_tree().quit(1)
		return
	if str(e_sprite.texture.resource_path).find("dungeon_entrance.png") == -1:
		push_error("US-015: entrance must use dungeon_entrance.png")
		get_tree().quit(1)
		return
	if str(x_sprite.texture.resource_path).find("dungeon_exit.png") == -1:
		push_error("US-015: exit must use dungeon_exit.png")
		get_tree().quit(1)
		return
	var layout := DungeonLayoutData.new()
	layout.entrance_cell = Vector2i(2, 2)
	layout.exit_cell = Vector2i(16, 16)
	layout.walkable_cells = [Vector2i(2, 2), Vector2i(3, 2), Vector2i(16, 16)]
	var builder := TilePlacementBuilder.new()
	var placements: Array[Dictionary] = builder.build(layout, DungeonGrid.set_from(layout.walkable_cells))
	var saw_entrance := false
	var saw_exit := false
	for item in placements:
		var role: String = str(item.get("tileRole", ""))
		var path: String = str(item.get("tileSourcePath", ""))
		if role == "entrance":
			saw_entrance = true
			if path != TileCatalog.ENTRANCE_SCENE_PATH:
				push_error("US-015: entrance placement path %s" % path)
				get_tree().quit(1)
				return
		if role == "exit":
			saw_exit = true
			if path != TileCatalog.EXIT_SCENE_PATH:
				push_error("US-015: exit placement path %s" % path)
				get_tree().quit(1)
				return
		if path == "res://level/outside_tile.tscn" or path == "res://level/floor.tscn" and (role == "entrance" or role == "exit"):
			push_error("US-015: mixed catalog on portal cell")
			get_tree().quit(1)
			return
	if not saw_entrance or not saw_exit:
		push_error("US-015: missing entrance/exit placements")
		get_tree().quit(1)
		return
	print("US-015 portal art test passed")
	get_tree().quit(0)
