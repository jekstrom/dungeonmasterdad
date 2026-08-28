extends Node

func _ready() -> void:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager == null or not manager.has_method("generate_dungeon_contract"):
		push_error("Skeleton-only spawns test: DungeonGenerationManager missing")
		return

	var response: Dictionary = manager.generate_dungeon_contract({
		"requestId": "skeleton-only-spawns",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {"origin": {"x": 0, "y": 0}, "size": {"x": 24, "y": 24}},
		"roomCount": 4
	}, 1)
	if not response.get("ok", false):
		push_error("Skeleton-only spawns test failed generation: %s" % response)
		return

	var spawns: Array = response.get("data", {}).get("monsterSpawns", [])
	if spawns.is_empty():
		push_error("Skeleton-only spawns test failed: no monster spawns")
		return
	for spawn in spawns:
		var type_id: String = str(spawn.get("monsterTypeId", ""))
		var scene_path: String = str(spawn.get("monsterScenePath", ""))
		if type_id != "skeleton":
			push_error("Skeleton-only spawns test failed: type %s" % type_id)
			return
		if scene_path != "res://monsters/skeleton/skeleton.tscn":
			push_error("Skeleton-only spawns test failed: path %s" % scene_path)
			return

	print("Skeleton-only spawns test passed: count=", spawns.size())
	get_tree().quit(0)
