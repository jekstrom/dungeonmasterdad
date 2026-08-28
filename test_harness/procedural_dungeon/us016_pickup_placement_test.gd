extends Node

const Planner = preload("res://scripts/procedural_dungeon/pickup_spawn_planner.gd")

func _ready() -> void:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager == null or not manager.has_method("generate_dungeon_contract"):
		_fail("US-016 T001: DungeonGenerationManager missing")
		return

	var payload := {
		"requestId": "us016-pickup-placement",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {
			"origin": {"x": 0, "y": 0},
			"size": {"x": 24, "y": 24}
		}
	}
	var response: Dictionary = manager.generate_dungeon_contract(payload, 1)
	if not response.get("ok", false):
		_fail("US-016 T001: generation failed %s" % response)
		return

	var data: Dictionary = response.get("data", {})
	if not _validate_pickups(data):
		return

	var response_b: Dictionary = manager.generate_dungeon_contract(payload, 1)
	if not response_b.get("ok", false):
		_fail("US-016 T001: second generation failed")
		return
	if str(response_b.get("data", {}).get("itemPickups", [])) != str(data.get("itemPickups", [])):
		_fail("US-016 T001: same seed must produce the same pickups")
		return

	print("US-016 T001 pickup placement test passed")
	get_tree().quit(0)

func _validate_pickups(data: Dictionary) -> bool:
	var entrance: Vector2i = _as_cell(data.get("entrance", {}))
	var exit_cell: Vector2i = _as_cell(data.get("exit", {}))
	var walkable: Dictionary = _reachable_set(data)
	var pickups: Array = data.get("itemPickups", [])
	var dew_count: int = 0
	var die_count: int = 0
	var used: Dictionary = {}
	for pickup in pickups:
		var item_type: String = str(pickup.get("item_type", ""))
		var cell: Vector2i = _as_cell(pickup.get("position", {}))
		if not walkable.has(cell):
			_fail("US-016 T001: pickup %s at %s is not walkable" % [item_type, cell])
			return false
		if cell == entrance or cell == exit_cell:
			_fail("US-016 T001: pickup must not sit on entrance or exit")
			return false
		if item_type == Planner.GREEN_DEW_PATH:
			dew_count += 1
		elif item_type == Planner.D6_PATH or item_type == Planner.D20_PATH:
			die_count += 1
		if used.has(cell):
			_fail("US-016 T001: default placement must not stack pickups on %s" % cell)
			return false
		used[cell] = true
	if dew_count < 1:
		_fail("US-016 T001: expected at least one green Dew")
		return false
	if die_count < 1:
		_fail("US-016 T001: expected at least one die")
		return false
	return true

func _reachable_set(data: Dictionary) -> Dictionary:
	var cells: Dictionary = {}
	for region in data.get("roomRegions", []):
		for point in region.get("cells", []):
			cells[_as_cell(point)] = true
	for region in data.get("hallwayRegions", []):
		for point in region.get("cells", []):
			cells[_as_cell(point)] = true
	return cells

func _as_cell(raw_value: Variant) -> Vector2i:
	return DungeonGrid.cell_from(raw_value)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
