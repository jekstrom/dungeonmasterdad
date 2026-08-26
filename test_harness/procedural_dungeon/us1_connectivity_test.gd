extends Node

func _ready() -> void:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if not manager:
		push_error("US1 connectivity test: DungeonGenerationManager autoload not found")
		return

	if not manager.has_method("generate_dungeon_contract"):
		push_error("US1 connectivity test: generate_dungeon_contract() not available")
		return

	var payload: Dictionary = {
		"requestId": "us1-connectivity-smoke",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 10, "y": 10},
		"generationBounds": {
			"origin": {"x": 0, "y": 0},
			"size": {"x": 20, "y": 20}
		}
	}

	var response: Dictionary = manager.generate_dungeon_contract(payload, 1)
	if not response.get("ok", false):
		push_error("US1 connectivity test failed: %s" % response)
		return

	var data: Dictionary = response.get("data", {})
	var entrance: Dictionary = data.get("entrance", {})
	var exit_point: Dictionary = data.get("exit", {})
	var main_path: Array = data.get("mainPath", [])

	if entrance.get("x", -1) != 2 or entrance.get("y", -1) != 2:
		push_error("US1 connectivity test failed: entrance mismatch")
		return

	if exit_point.get("x", -1) != 10 or exit_point.get("y", -1) != 10:
		push_error("US1 connectivity test failed: exit mismatch")
		return

	if main_path.is_empty():
		push_error("US1 connectivity test failed: main path is empty")
		return

	print("US1 connectivity test passed: generated path with ", main_path.size(), " cells")
