extends Node

func _ready() -> void:
	var dungeon_local := Rect2i(0, 0, 12, 10)
	var delta: Vector2i = MapBounds.cell_translation_for_east_flush(dungeon_local)
	var dungeon := Rect2i(dungeon_local.position + delta, dungeon_local.size)
	var interior: Rect2i = MapBounds.interior_from_dungeon_aabb(dungeon)
	var exit_cell := Vector2i(dungeon.position.x, dungeon.position.y + int(dungeon.size.y / 2))
	var entrance_cell := Vector2i(dungeon.end.x - 1, dungeon.position.y + int(dungeon.size.y / 2))

	if interior.size.x * interior.size.y < 4 * dungeon.size.x * dungeon.size.y:
		push_error("US-024 T015: interior area must be >= 4x dungeon AABB")
		get_tree().quit(1)
		return
	if dungeon.end.x != interior.end.x:
		push_error("US-024 T015: dungeon must be flush to east interior")
		get_tree().quit(1)
		return
	if not _contains_rect(interior, dungeon):
		push_error("US-024 T015: dungeon AABB must sit inside interior")
		get_tree().quit(1)
		return
	if interior.position != Vector2i.ZERO:
		push_error("US-024 T015: east-flush interior origin should be (0,0), got %s" % interior.position)
		get_tree().quit(1)
		return

	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	add_child(level)
	await get_tree().process_frame
	level.apply_map_interior(interior, dungeon, exit_cell)
	await get_tree().process_frame

	var bounds: MapBounds = level.map_bounds
	if not bounds.has_committed_bounds():
		push_error("US-024 T015: map bounds not committed")
		get_tree().quit(1)
		return

	var catalog := CliffCatalog.new()
	var cliff_parent: Node = level.get_node_or_null("CliffTiles")
	if cliff_parent == null:
		push_error("US-024 T015: CliffTiles missing")
		get_tree().quit(1)
		return
	var cliffs_by_cell: Dictionary = {}
	for child in cliff_parent.get_children():
		if catalog.is_dungeon_tile_path(child.scene_file_path):
			push_error("US-024 T015: cliff used dungeon catalog")
			get_tree().quit(1)
			return
		if child.scene_file_path != catalog.get_cliff_scene_path():
			push_error("US-024 T015: cliff scene path")
			get_tree().quit(1)
			return
		var world: Vector2 = child.position
		if child.has_method("grid_world_position"):
			world = child.grid_world_position()
		var cell: Vector2i = DungeonGrid.from_world(world)
		cliffs_by_cell[cell] = child
		var body: StaticBody2D = child.get_node_or_null("StaticBody")
		if body == null or body.collision_layer != 16:
			push_error("US-024 T015: cliff collision layer")
			get_tree().quit(1)
			return
	var expected_cliffs: int = (interior.size.x + 2) * (interior.size.y + 2) - interior.size.x * interior.size.y
	if cliffs_by_cell.size() != expected_cliffs:
		push_error("US-024 T015: expected %d cliffs, got %d" % [expected_cliffs, cliffs_by_cell.size()])
		get_tree().quit(1)
		return
	for x in range(interior.position.x, interior.end.x):
		if not cliffs_by_cell.has(Vector2i(x, interior.position.y - 1)) or not cliffs_by_cell.has(Vector2i(x, interior.end.y)):
			push_error("US-024 T015: missing north/south cliff")
			get_tree().quit(1)
			return
	for y in range(interior.position.y, interior.end.y):
		if not cliffs_by_cell.has(Vector2i(interior.position.x - 1, y)) or not cliffs_by_cell.has(Vector2i(interior.end.x, y)):
			push_error("US-024 T015: missing west/east cliff")
			get_tree().quit(1)
			return
	var corners: Array[Vector2i] = [
		Vector2i(interior.position.x - 1, interior.position.y - 1),
		Vector2i(interior.end.x, interior.position.y - 1),
		Vector2i(interior.position.x - 1, interior.end.y),
		Vector2i(interior.end.x, interior.end.y),
	]
	for corner in corners:
		if not cliffs_by_cell.has(corner):
			push_error("US-024 T015: missing cliff corner %s" % corner)
			get_tree().quit(1)
			return

	var west: Array[Vector2i] = level.west_spawn_cells()
	if west.is_empty():
		push_error("US-024 T015: west spawn strip empty")
		get_tree().quit(1)
		return
	for cell in west:
		if cell.x != interior.position.x:
			push_error("US-024 T015: west spawn not on west edge %s" % cell)
			get_tree().quit(1)
			return
		if dungeon.has_point(cell) or bounds.is_cliff_cell(cell) or not bounds.is_interior_cell(cell):
			push_error("US-024 T015: west spawn illegal cell %s" % cell)
			get_tree().quit(1)
			return
	var spawn_world: Vector2 = level.take_west_spawn_world()
	if not bounds.is_world_position_in_interior(spawn_world):
		push_error("US-024 T015: west spawn world not interior")
		get_tree().quit(1)
		return

	if not dungeon.has_point(entrance_cell) or not interior.has_point(entrance_cell):
		push_error("US-024 T015: entrance must sit in the east dungeon")
		get_tree().quit(1)
		return
	if entrance_cell.x <= interior.position.x:
		push_error("US-024 T015: entrance is not on the east dungeon")
		get_tree().quit(1)
		return
	var entrance_world: Vector2 = DungeonGrid.to_world_center(entrance_cell)
	if not bounds.is_world_position_in_interior(entrance_world):
		push_error("US-024 T015: entrance world not interior")
		get_tree().quit(1)
		return

	var outside_parent: Node = level.get_node_or_null("OutsideTiles")
	if outside_parent == null:
		push_error("US-024 T015: OutsideTiles missing")
		get_tree().quit(1)
		return
	var expected_outside: int = interior.size.x * interior.size.y - dungeon.size.x * dungeon.size.y
	if outside_parent.get_child_count() != expected_outside:
		push_error("US-024 T015: expected %d outside tiles, got %d" % [expected_outside, outside_parent.get_child_count()])
		get_tree().quit(1)
		return
	for child in outside_parent.get_children():
		if not (child is OutsideTile) or child.scene_file_path == "res://level/floor.tscn":
			push_error("US-024 T015: dungeon floor used as overworld")
			get_tree().quit(1)
			return
		var cell: Vector2i = DungeonGrid.from_world(child.position)
		if dungeon.has_point(cell) or bounds.is_cliff_cell(cell) or not bounds.is_interior_cell(cell):
			push_error("US-024 T015: outside tile on illegal cell %s" % cell)
			get_tree().quit(1)
			return

	var eligible: Array[Vector2i] = level.tree_scatter_eligible_cells()
	var tree_parent: Node = level.get_node_or_null("ScatteredTrees")
	if tree_parent == null or eligible.is_empty():
		push_error("US-024 T015: tree scatter missing")
		get_tree().quit(1)
		return
	var tree_count: int = tree_parent.get_child_count()
	var expected_trees: int = int(round(float(eligible.size()) * float(level.tree_scatter_density)))
	if tree_count != expected_trees:
		push_error("US-024 T015: expected %d trees, got %d" % [expected_trees, tree_count])
		get_tree().quit(1)
		return
	var ratio: float = float(tree_count) / float(eligible.size())
	if ratio < 0.04 or ratio > 0.12:
		push_error("US-024 T015: tree density %s outside 4-12%%" % ratio)
		get_tree().quit(1)
		return
	for child in tree_parent.get_children():
		var cell: Vector2i = DungeonGrid.from_world(child.position)
		if not eligible.has(cell):
			push_error("US-024 T015: tree on ineligible cell %s" % cell)
			get_tree().quit(1)
			return
		if dungeon.has_point(cell) or bounds.is_cliff_cell(cell) or west.has(cell):
			push_error("US-024 T015: tree on banned cell %s" % cell)
			get_tree().quit(1)
			return

	var past_west := Vector2(-400, DungeonGrid.CELL_PX)
	if bounds.is_world_position_walkable(past_west):
		push_error("US-024 T015: void probe treated as walkable")
		get_tree().quit(1)
		return
	var clamped: Vector2 = level.clamp_world_to_interior(past_west)
	if not bounds.is_world_position_walkable(clamped):
		push_error("US-024 T015: clamp did not land in walkable bounds")
		get_tree().quit(1)
		return
	var origin: Vector2 = DungeonGrid.to_world(interior.position)
	if clamped.x >= origin.x:
		push_error("US-024 T015: clamp must reach the west cliff lip")
		get_tree().quit(1)
		return
	var pusher := CharacterBody2D.new()
	add_child(pusher)
	pusher.global_position = Vector2(-400, 64)
	pusher.velocity = Vector2(-400, 0)
	level.enforce_body_interior(pusher)
	if not bounds.is_world_position_walkable(pusher.global_position):
		push_error("US-024 T015: player was not clamped at the cliff")
		get_tree().quit(1)
		return
	var monster := CharacterBody2D.new()
	monster.add_to_group("generated_dungeon_monsters")
	add_child(monster)
	monster.global_position = Vector2(64, -400)
	level.enforce_body_interior(monster)
	if not bounds.is_world_position_walkable(monster.global_position):
		push_error("US-024 T015: monster was not clamped at the cliff")
		get_tree().quit(1)
		return
	if monster.global_position.y >= origin.y:
		push_error("US-024 T015: clamp must reach the north cliff lip")
		get_tree().quit(1)
		return

	var reality: RealityZone = load("res://zones/reality_zone.tscn").instantiate()
	var fantasy: Zone = load("res://zones/fantasy_zone.tscn").instantiate()
	add_child(reality)
	add_child(fantasy)
	await get_tree().process_frame
	if not _rect_inside_interior(reality.home_rect, bounds) or reality.home_rect.position.x != interior.position.x:
		push_error("US-024 T015: Reality home not clipped to west interior")
		get_tree().quit(1)
		return
	if not _rect_inside_interior(fantasy.home_rect, bounds):
		push_error("US-024 T015: Fantasy home not clipped to interior")
		get_tree().quit(1)
		return
	var pocket: Rect2i = reality.clip_pocket_rect(Rect2i(interior.position.x - 3, interior.position.y - 2, 6, 5))
	if not _rect_inside_interior(pocket, bounds):
		push_error("US-024 T015: pocket was not truncated to interior")
		get_tree().quit(1)
		return

	if Lobby.is_network_server():
		push_error("US-024 T015: harness must run on OfflineMultiplayerPeer")
		get_tree().quit(1)
		return
	var waiting := Node2D.new()
	waiting.set_script(load("res://_globals/level_manager.gd"))
	add_child(waiting)
	await get_tree().process_frame
	waiting.commit_map_interior(interior)
	if waiting.has_map_bounds():
		push_error("US-024 T015: client must wait for host map payload")
		get_tree().quit(1)
		return
	var joiner := Node2D.new()
	joiner.set_script(load("res://_globals/level_manager.gd"))
	add_child(joiner)
	await get_tree().process_frame
	joiner.tree_scatter_density = 1.0
	joiner.apply_map_sync_payload(level.build_map_sync_payload())
	await get_tree().process_frame
	if joiner.map_bounds.get_interior() != interior or joiner.dungeon_cell_bounds() != dungeon:
		push_error("US-024 T015: late joiner map bounds mismatch")
		get_tree().quit(1)
		return
	if joiner.get_node("OutsideTiles").get_child_count() != outside_parent.get_child_count():
		push_error("US-024 T015: late joiner outside fill mismatch")
		get_tree().quit(1)
		return
	if joiner.get_node("ScatteredTrees").get_child_count() != tree_count:
		push_error("US-024 T015: late joiner tree set mismatch")
		get_tree().quit(1)
		return
	if joiner.get_node("CliffTiles").get_child_count() != cliffs_by_cell.size():
		push_error("US-024 T015: late joiner cliff ring mismatch")
		get_tree().quit(1)
		return

	print("US-024 T015 independent test passed")
	get_tree().quit(0)

func _contains_rect(outer: Rect2i, inner: Rect2i) -> bool:
	return (
		inner.position.x >= outer.position.x
		and inner.position.y >= outer.position.y
		and inner.end.x <= outer.end.x
		and inner.end.y <= outer.end.y
	)

func _rect_inside_interior(rect: Rect2i, bounds: MapBounds) -> bool:
	if rect.size.x <= 0 or rect.size.y <= 0:
		return false
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var cell := Vector2i(x, y)
			if not bounds.is_interior_cell(cell) or bounds.is_cliff_cell(cell):
				return false
	return true
