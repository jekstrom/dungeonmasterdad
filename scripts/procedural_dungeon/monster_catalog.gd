class_name MonsterCatalog extends RefCounted

const MONSTER_SCENES: Dictionary = {
	"goblin": "res://monsters/goblin.tscn",
	"skeleton": "res://monsters/skeleton/skeleton.tscn",
	"knight": "res://monsters/knight/knight.tscn",
	"baja_boss": "res://monsters/baja_boss.tscn"
}

func get_approved_scene_paths() -> PackedStringArray:
	return PackedStringArray(MONSTER_SCENES.values())

func is_approved_scene_path(scene_path: String) -> bool:
	return get_approved_scene_paths().has(scene_path)

func get_scene_path(monster_type_id: String) -> String:
	return str(MONSTER_SCENES.get(monster_type_id, ""))

func get_monster_type_ids() -> PackedStringArray:
	return PackedStringArray(MONSTER_SCENES.keys())
