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
		"startPosition": {"x": 2, "y": 2},
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

	var room_set: Dictionary = {}
	var start_set: Dictionary = {}
	var mid_set: Dictionary = {}
	for region in data.get("roomRegions", []):
		var role: String = str(region.get("role", ""))
		for point in region.get("cells", []):
			var cell: Vector2i = _as_cell(point)
			room_set[cell] = true
			if role == "start":
				start_set[cell] = true
			elif role == "mid":
				mid_set[cell] = true

	for placement in data.get("tilePlacements", []):
		var scene_path: String = str(placement.get("tileSourcePath", ""))
		if not tile_catalog.is_approved_scene_path(scene_path):
			push_error("US3 content compliance failed: non-catalog tile path %s" % scene_path)
			return
		var tile_role: String = str(placement.get("tileRole", ""))
		if tile_role == "wall":
			var wall_type: int = int(placement.get("variantId", -1))
			if wall_type < 0 or wall_type > 3:
				push_error("US3 content compliance failed: illegal wall_type")
				return
			continue
		var cell: Vector2i = _as_cell(placement.get("position", {}))
		var floor_type: int = int(placement.get("variantId", -1))
		if room_set.has(cell) or tile_role == "entrance" or tile_role == "exit":
			if floor_type != 0:
				push_error("US3 content compliance failed: room floor_type != 0")
				return
		else:
			if floor_type != 1:
				push_error("US3 content compliance failed: hallway floor_type != 1")
				return

	var entrance: Dictionary = data.get("entrance", {})
	var exit_point: Dictionary = data.get("exit", {})
	var entrance_cell: Vector2i = _as_cell(entrance)
	var exit_cell: Vector2i = _as_cell(exit_point)
	var forbidden: Dictionary = {
		entrance_cell: true,
		exit_cell: true
	}
	for neighbor in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		forbidden[entrance_cell + neighbor] = true
		forbidden[exit_cell + neighbor] = true

	var knight_count: int = 0
	var mid_spawns: int = 0
	for spawn in data.get("monsterSpawns", []):
		var scene_path: String = str(spawn.get("monsterScenePath", ""))
		if not monster_catalog.is_approved_scene_path(scene_path):
			push_error("US3 content compliance failed: non-catalog monster path %s" % scene_path)
			return
		var spawn_cell: Vector2i = _as_cell(spawn.get("position", {}))
		if forbidden.has(spawn_cell):
			push_error("US3 content compliance failed: spawn on entrance/exit neighborhood")
			return
		if start_set.has(spawn_cell):
			push_error("US3 content compliance failed: spawn in start room")
			return
		if mid_set.has(spawn_cell):
			mid_spawns += 1
		if str(spawn.get("monsterTypeId", "")) == "knight":
			knight_count += 1

	if mid_spawns < 1:
		push_error("US3 content compliance failed: no spawn in a mid room")
		return
	if knight_count > 1:
		push_error("US3 content compliance failed: knight count > 1")
		return

	print("US3 content compliance test passed")

func _as_cell(raw_value: Variant) -> Vector2i:
	if raw_value is Vector2i:
		return raw_value
	if raw_value is Dictionary:
		return Vector2i(int(raw_value.get("x", 0)), int(raw_value.get("y", 0)))
	return Vector2i.ZERO
