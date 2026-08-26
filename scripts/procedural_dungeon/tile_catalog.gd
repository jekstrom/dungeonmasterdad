class_name TileCatalog extends RefCounted

const FLOOR_SCENE_PATH: String = "res://level/floor.tscn"
const WALL_SCENE_PATH: String = "res://level/wall.tscn"

func get_floor_scene_path() -> String:
	return FLOOR_SCENE_PATH

func get_wall_scene_path() -> String:
	return WALL_SCENE_PATH

func get_approved_scene_paths() -> PackedStringArray:
	return PackedStringArray([FLOOR_SCENE_PATH, WALL_SCENE_PATH])

func is_approved_scene_path(scene_path: String) -> bool:
	return get_approved_scene_paths().has(scene_path)

func is_valid_for_role(tile_role: String, scene_path: String) -> bool:
	if not is_approved_scene_path(scene_path):
		return false
	if tile_role == "wall":
		return scene_path == WALL_SCENE_PATH
	return scene_path == FLOOR_SCENE_PATH
