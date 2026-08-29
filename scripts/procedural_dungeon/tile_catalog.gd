class_name TileCatalog extends RefCounted

const FLOOR_SCENE_PATH: String = "res://level/floor.tscn"
const WALL_SCENE_PATH: String = "res://level/wall.tscn"
const ENTRANCE_SCENE_PATH: String = "res://level/dungeon_entrance.tscn"

func get_floor_scene_path() -> String:
	return FLOOR_SCENE_PATH

func get_wall_scene_path() -> String:
	return WALL_SCENE_PATH

func get_entrance_scene_path() -> String:
	return ENTRANCE_SCENE_PATH

func get_approved_scene_paths() -> PackedStringArray:
	return PackedStringArray([FLOOR_SCENE_PATH, WALL_SCENE_PATH, ENTRANCE_SCENE_PATH])

func is_approved_scene_path(scene_path: String) -> bool:
	return get_approved_scene_paths().has(scene_path)

static func is_dungeon_catalog_path(scene_path: String) -> bool:
	return (
		scene_path == FLOOR_SCENE_PATH
		or scene_path == WALL_SCENE_PATH
		or scene_path == ENTRANCE_SCENE_PATH
	)

func is_valid_for_role(tile_role: String, scene_path: String) -> bool:
	if tile_role == "wall":
		return scene_path == WALL_SCENE_PATH
	if tile_role == "entrance":
		return scene_path == ENTRANCE_SCENE_PATH
	return scene_path == FLOOR_SCENE_PATH
