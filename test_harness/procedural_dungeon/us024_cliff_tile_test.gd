extends Node

func _ready() -> void:
	var catalog := CliffCatalog.new()
	if catalog.get_cliff_scene_path() != "res://level/cliff.tscn":
		push_error("US-024 T002: cliff catalog path must be level/cliff.tscn")
		get_tree().quit(1)
		return
	if catalog.is_approved_scene_path("res://level/wall.tscn") or catalog.is_approved_scene_path("res://level/floor.tscn"):
		push_error("US-024 T002: dungeon tiles must not be in the cliff catalog")
		get_tree().quit(1)
		return
	if catalog.is_dungeon_tile_path("res://level/cliff.tscn"):
		push_error("US-024 T002: cliff scene must not be classified as a dungeon tile")
		get_tree().quit(1)
		return
	if not catalog.is_approved_scene_path("res://level/cliff.tscn"):
		push_error("US-024 T002: cliff scene must be approved")
		get_tree().quit(1)
		return

	var interior := Rect2i(10, 20, 8, 6)
	if catalog.cliff_frame_for_cell(interior, Vector2i(10, 19)) != int(CliffDoodad.CliffFrame.N):
		push_error("US-024 T002: north edge frame")
		get_tree().quit(1)
		return
	if catalog.cliff_frame_for_cell(interior, Vector2i(18, 22)) != int(CliffDoodad.CliffFrame.E):
		push_error("US-024 T002: east edge frame")
		get_tree().quit(1)
		return
	if catalog.cliff_frame_for_cell(interior, Vector2i(12, 26)) != int(CliffDoodad.CliffFrame.S):
		push_error("US-024 T002: south edge frame")
		get_tree().quit(1)
		return
	if catalog.cliff_frame_for_cell(interior, Vector2i(9, 21)) != int(CliffDoodad.CliffFrame.W):
		push_error("US-024 T002: west edge frame")
		get_tree().quit(1)
		return
	if catalog.cliff_frame_for_cell(interior, Vector2i(9, 19)) != int(CliffDoodad.CliffFrame.NW):
		push_error("US-024 T002: NW corner frame")
		get_tree().quit(1)
		return
	if catalog.cliff_frame_for_cell(interior, Vector2i(18, 26)) != int(CliffDoodad.CliffFrame.SE):
		push_error("US-024 T002: SE corner frame")
		get_tree().quit(1)
		return
	if catalog.cliff_frame_for_cell(interior, Vector2i(10, 20)) != int(CliffDoodad.CliffFrame.VOID):
		push_error("US-024 T002: interior cell must not map to an edge frame")
		get_tree().quit(1)
		return

	var packed: PackedScene = load("res://level/cliff.tscn")
	if packed == null:
		push_error("US-024 T002: failed to load cliff.tscn")
		get_tree().quit(1)
		return
	var cliff: CliffDoodad = packed.instantiate() as CliffDoodad
	if cliff == null:
		push_error("US-024 T002: cliff.tscn is not a CliffDoodad")
		get_tree().quit(1)
		return
	add_child(cliff)
	await get_tree().process_frame
	var body: StaticBody2D = cliff.get_node_or_null("StaticBody")
	if body == null or body.collision_layer != 16:
		push_error("US-024 T002: cliff StaticBody must use wall collision layer 16")
		get_tree().quit(1)
		return
	if body.collision_mask != 0:
		push_error("US-024 T002: cliff StaticBody mask should be 0")
		get_tree().quit(1)
		return
	var sprite: Sprite2D = cliff.get_node_or_null("Sprite2D")
	var grass_sprite: Sprite2D = cliff.get_node_or_null("Grass")
	if sprite == null:
		push_error("US-024 T002: stone sprite missing")
		get_tree().quit(1)
		return
	if grass_sprite == null or grass_sprite.z_index >= 0 or grass_sprite.z_as_relative:
		push_error("US-024 T002: grass sprite must draw behind the player")
		get_tree().quit(1)
		return
	if sprite.offset.y >= -70.0:
		push_error("US-024 T002: north stone sprite must sit on the lip, not the full cell")
		get_tree().quit(1)
		return
	if cliff.y_sort_enabled:
		push_error("US-024 T002: cliff node y_sort must stay off so CliffTiles sorts the lip")
		get_tree().quit(1)
		return
	if cliff.position.y >= 0.0:
		push_error("US-024 T002: north cliff must y-sort at the stone lip, not the south grass")
		get_tree().quit(1)
		return
	var north_sort_y: float = cliff.position.y
	if sprite.texture == null:
		push_error("US-024 T002: placeholder texture missing")
		get_tree().quit(1)
		return
	var atlas_path := ""
	var atlas_tex: Texture2D = null
	if sprite.texture is AtlasTexture:
		atlas_tex = (sprite.texture as AtlasTexture).atlas
		if atlas_tex:
			atlas_path = atlas_tex.resource_path
	if atlas_path.find("cubicle_stone_wall") != -1:
		push_error("US-024 T002: must not reuse cubicle_stone_wall.png")
		get_tree().quit(1)
		return
	if atlas_tex == null or atlas_tex.get_width() != 1024 or atlas_tex.get_height() != 128:
		push_error("US-024 T003: cliff atlas must be 1024x128 (8x128 frames)")
		get_tree().quit(1)
		return
	if atlas_path.find("cliff_edges.png") == -1:
		push_error("US-024 T003: cliff tile must use sprites/cliff_edges.png")
		get_tree().quit(1)
		return
	var shape_a: CollisionShape2D = body.get_node_or_null("CollisionShape2D")
	if shape_a == null or shape_a.disabled or shape_a.shape == null:
		push_error("US-024 T002: north lip collision missing")
		get_tree().quit(1)
		return
	if (shape_a.shape as RectangleShape2D).size.y >= 120.0:
		push_error("US-024 T002: north collision must leave interior-facing grass walkable")
		get_tree().quit(1)
		return
	if shape_a.position.y > -80.0:
		push_error("US-024 T002: north lip must sit on the void side, not interior grass")
		get_tree().quit(1)
		return
	cliff.cliff_frame = CliffDoodad.CliffFrame.S
	await get_tree().process_frame
	if cliff.position.y < north_sort_y + 40.0:
		push_error("US-024 T002: south cliff should y-sort at the south foot")
		get_tree().quit(1)
		return
	if shape_a.disabled or shape_a.shape == null:
		push_error("US-024 T002: south lip collision missing")
		get_tree().quit(1)
		return
	if shape_a.position.y < -40.0:
		push_error("US-024 T002: south lip must sit on the drop-off face, not interior grass")
		get_tree().quit(1)
		return
	cliff.cliff_frame = CliffDoodad.CliffFrame.E
	await get_tree().process_frame
	if shape_a.position.x < 20.0:
		push_error("US-024 T002: east lip must sit on the void side, not interior grass")
		get_tree().quit(1)
		return
	cliff.cliff_frame = CliffDoodad.CliffFrame.W
	await get_tree().process_frame
	if shape_a.position.x > -20.0:
		push_error("US-024 T002: west lip must sit on the void side, not interior grass")
		get_tree().quit(1)
		return
	cliff.cliff_frame = CliffDoodad.CliffFrame.N
	await get_tree().process_frame
	cliff.cliff_frame = CliffDoodad.CliffFrame.VOID
	await get_tree().process_frame
	if shape_a.disabled or shape_a.shape == null:
		push_error("US-024 T002: void collision missing")
		get_tree().quit(1)
		return
	var void_size: Vector2 = (shape_a.shape as RectangleShape2D).size
	if void_size.x < 120.0 or void_size.y < 120.0:
		push_error("US-024 T002: void collision should fill the cell")
		get_tree().quit(1)
		return
	cliff.cliff_frame = CliffDoodad.CliffFrame.SE
	await get_tree().process_frame
	var shape_b: CollisionShape2D = body.get_node_or_null("CollisionShape2D2")
	if shape_b == null or shape_b.disabled:
		push_error("US-024 T002: corner needs both lip colliders")
		get_tree().quit(1)
		return

	print("US-024 T002 cliff tile test passed")
	get_tree().quit(0)
