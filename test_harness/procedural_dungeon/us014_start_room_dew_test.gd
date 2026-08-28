extends Node

const Planner = preload("res://scripts/procedural_dungeon/pickup_spawn_planner.gd")

func _ready() -> void:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager == null or not manager.has_method("generate_dungeon_contract"):
		_fail("US-014 start-room Dew: DungeonGenerationManager missing")
		return

	var response: Dictionary = manager.generate_dungeon_contract({
		"requestId": "us014-start-room-dew",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {
			"origin": {"x": 0, "y": 0},
			"size": {"x": 24, "y": 24}
		}
	}, 1)
	if not response.get("ok", false):
		_fail("US-014 start-room Dew: generation failed %s" % response)
		return

	var data: Dictionary = response.get("data", {})
	var entrance: Vector2i = _as_cell(data.get("entrance", {}))
	var exit_cell: Vector2i = _as_cell(data.get("exit", {}))
	var start_set: Dictionary = {}
	for region in data.get("roomRegions", []):
		if str(region.get("role", "")) != "start":
			continue
		for point in region.get("cells", []):
			start_set[_as_cell(point)] = true

	var pickups: Array = data.get("itemPickups", [])
	var dew_pickups: Array = []
	for pickup in pickups:
		if str(pickup.get("item_type", "")) == Planner.GREEN_DEW_PATH:
			dew_pickups.append(pickup)
	var used: Dictionary = {}
	var start_dew_count: int = 0
	for dew in dew_pickups:
		var dew_cell: Vector2i = _as_cell(dew.get("position", {}))
		if dew_cell == entrance:
			_fail("US-014 start-room Dew: Dew must not sit on the entrance cell")
			return
		if dew_cell == exit_cell:
			_fail("US-014 start-room Dew: Dew must not sit on the exit cell")
			return
		if not start_set.has(dew_cell):
			continue
		if used.has(dew_cell):
			_fail("US-014 start-room Dew: Dew cells must be distinct")
			return
		used[dew_cell] = true
		start_dew_count += 1
	if start_dew_count < Planner.START_ROOM_DEW_COUNT:
		_fail("US-014 start-room Dew: expected at least %d start-room Dew, got %d" % [Planner.START_ROOM_DEW_COUNT, start_dew_count])
		return

	print("US-014 start-room Dew test passed")
	get_tree().quit(0)

func _as_cell(raw_value: Variant) -> Vector2i:
	if raw_value is Vector2i:
		return raw_value
	if raw_value is Dictionary:
		return Vector2i(int(raw_value.get("x", 0)), int(raw_value.get("y", 0)))
	return Vector2i.ZERO

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
