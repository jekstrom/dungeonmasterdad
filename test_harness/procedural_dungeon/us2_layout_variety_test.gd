extends Node

func _ready() -> void:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if not manager:
		push_error("US2 layout variety test: DungeonGenerationManager autoload not found")
		return

	if not manager.has_method("generate_dungeon_contract"):
		push_error("US2 layout variety test: generate_dungeon_contract() not available")
		return

	var signatures: Dictionary = {}
	for i in range(6):
		var payload: Dictionary = {
			"requestId": "us2-variety-%d" % i,
			"startPosition": {"x": 2 + i, "y": 2},
			"exitPosition": {"x": 12, "y": 12 - i},
			"generationBounds": {
				"origin": {"x": 0, "y": 0},
				"size": {"x": 24, "y": 24}
			}
		}

		var response: Dictionary = manager.generate_dungeon_contract(payload, 1)
		if not response.get("ok", false):
			push_error("US2 layout variety test failed generation: %s" % response)
			return

		var data: Dictionary = response.get("data", {})
		var room_regions: Array = data.get("roomRegions", [])
		var hallway_regions: Array = data.get("hallwayRegions", [])

		if room_regions.is_empty() or hallway_regions.is_empty():
			push_error("US2 layout variety test failed: missing room or hallway region")
			return

		var signature: String = _build_signature(data)
		signatures[signature] = true

	if signatures.size() <= 1:
		push_error("US2 layout variety test failed: generated layouts did not vary")
		return

	print("US2 layout variety test passed: unique signatures=", signatures.size())

func _build_signature(data: Dictionary) -> String:
	var room_regions: Array = data.get("roomRegions", [])
	var hallway_regions: Array = data.get("hallwayRegions", [])
	var main_path: Array = data.get("mainPath", [])
	return "%s|%s|%s" % [room_regions.size(), hallway_regions.size(), main_path.size()]
