class_name DungeonSceneBuilder extends RefCounted

const TileCatalog = preload("res://scripts/procedural_dungeon/tile_catalog.gd")
const DungeonLayoutData = preload("res://scripts/procedural_dungeon/resources/dungeon_layout_data.gd")

const FLOOR_Z_INDEX := -1
const WALL_Z_INDEX := 0

var _tile_catalog: TileCatalog = TileCatalog.new()

func build_container(layout_data: DungeonLayoutData) -> Dictionary:
	var container_scene: PackedScene = load("res://scenes/generated_dungeon_container.tscn")
	if not container_scene:
		return _fail("LAYOUT_INFEASIBLE", "Generated dungeon container scene missing")

	var container: Node2D = container_scene.instantiate() as Node2D
	if not container:
		return _fail("LAYOUT_INFEASIBLE", "Failed to instantiate generated dungeon container")

	var tiles_root: Node2D = container.get_node_or_null("Tiles") as Node2D
	if not tiles_root:
		container.queue_free()
		return _fail("LAYOUT_INFEASIBLE", "Generated container is missing Tiles node")

	var floor_scene: PackedScene = load(_tile_catalog.get_floor_scene_path())
	var wall_scene: PackedScene = load(_tile_catalog.get_wall_scene_path())
	if not floor_scene or not wall_scene:
		container.queue_free()
		return _fail("LAYOUT_INFEASIBLE", "Required tile scenes are unavailable")

	for placement in layout_data.tile_placements:
		var tile_role: String = str(placement.get("tileRole", ""))
		var scene_path: String = str(placement.get("tileSourcePath", ""))
		if not _tile_catalog.is_valid_for_role(tile_role, scene_path):
			container.queue_free()
			return _fail("INVALID_REQUEST", "Tile placement references non-catalog path")

		var tile_node: Node2D = null
		if tile_role == "wall":
			tile_node = wall_scene.instantiate() as Node2D
		else:
			tile_node = floor_scene.instantiate() as Node2D

		if not tile_node:
			continue

		var point: Dictionary = placement.get("position", {})
		tile_node.position = Vector2(float(point.get("x", 0)) * 128.0, float(point.get("y", 0)) * 128.0)
		var variant_id: int = int(placement.get("variantId", -1))
		if tile_role == "wall":
			if "wall_type" in tile_node:
				var wall_type: int = variant_id
				if wall_type < 0:
					wall_type = 1
				tile_node.wall_type = 2 if wall_type == 2 else 1
			if "wall_frame" in tile_node:
				var wall_frame: int = int(placement.get("wallFrame", -1))
				if wall_frame >= 0:
					tile_node.wall_frame = wall_frame
			tile_node.z_index = WALL_Z_INDEX
			tile_node.add_to_group("wall")
		else:
			if "floor_type" in tile_node:
				var floor_type: int = variant_id
				if floor_type < 0:
					floor_type = 0
				tile_node.floor_type = clampi(floor_type, 0, 1)
			tile_node.z_index = FLOOR_Z_INDEX
			if tile_role == "entrance":
				tile_node.add_to_group("entrance")
				tile_node.add_to_group("room")
			elif tile_role == "exit":
				tile_node.add_to_group("exit")
				tile_node.add_to_group("room")
			elif variant_id == 1:
				tile_node.add_to_group("hallway")
			else:
				tile_node.add_to_group("room")
		tiles_root.add_child(tile_node)

	return {
		"ok": true,
		"container": container
	}

func _fail(error_code: String, message: String) -> Dictionary:
	return {
		"ok": false,
		"error_code": error_code,
		"message": message
	}
