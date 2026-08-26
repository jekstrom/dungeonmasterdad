extends Node

const TileCatalog = preload("res://scripts/procedural_dungeon/tile_catalog.gd")
const MonsterCatalog = preload("res://scripts/procedural_dungeon/monster_catalog.gd")

func _ready() -> void:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if not manager:
		push_error("US3 content compliance test: DungeonGenerationManager autoload not found")
		return

	if not manager.has_method("generate_dungeon_contract"):
		push_error("US3 content compliance test: generate_dungeon_contract() not available")
		return

	var payload: Dictionary = {
		"requestId": "us3-content-compliance",
		"startPosition": {"x": 3, "y": 3},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {
			"origin": {"x": 0, "y": 0},
			"size": {"x": 24, "y": 24}
		}
	}

	var response: Dictionary = manager.generate_dungeon_contract(payload, 1)
	if not response.get("ok", false):
		push_error("US3 content compliance test failed generation: %s" % response)
		return

	var data: Dictionary = response.get("data", {})
	var tile_catalog: TileCatalog = TileCatalog.new()
	var monster_catalog: MonsterCatalog = MonsterCatalog.new()

	for placement in data.get("tilePlacements", []):
		var scene_path: String = str(placement.get("tileSourcePath", ""))
		if not tile_catalog.is_approved_scene_path(scene_path):
			push_error("US3 content compliance failed: non-catalog tile path %s" % scene_path)
			return

	var entrance: Dictionary = data.get("entrance", {})
	var exit_point: Dictionary = data.get("exit", {})
	for spawn in data.get("monsterSpawns", []):
		var scene_path: String = str(spawn.get("monsterScenePath", ""))
		if not monster_catalog.is_approved_scene_path(scene_path):
			push_error("US3 content compliance failed: non-catalog monster path %s" % scene_path)
			return

		var point: Dictionary = spawn.get("position", {})
		if point == entrance or point == exit_point:
			push_error("US3 content compliance failed: spawn placed on entrance/exit")
			return

	print("US3 content compliance test passed")
