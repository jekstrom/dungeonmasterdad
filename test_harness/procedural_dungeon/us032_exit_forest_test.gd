extends Node

## US-032 headless harness: dense exit forest + SkillTree, egress clear, sparse exclusion, rebuild.
## Covers west-edge exit (simple) and room-center exit (live room radius + wall shell).

func _ready() -> void:
	if not await _run_edge_exit_suite():
		return
	if not await _run_room_center_and_density_suite():
		return
	print("US-032 exit forest test passed")
	get_tree().quit(0)


func _run_edge_exit_suite() -> bool:
	var interior := Rect2i(0, 0, 16, 10)
	var dungeon := Rect2i(8, 2, 8, 6)
	var exit_a := Vector2i(8, 5)
	var exit_b := Vector2i(8, 3)

	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	add_child(level)
	await get_tree().process_frame

	# Authored playground-style SkillTree that must be superseded.
	var authored: Node2D = load("res://doodads/skill_tree.tscn").instantiate() as Node2D
	authored.name = "SkillTree"
	authored.position = Vector2(180, 58)
	authored.scale = Vector2(0.25, 0.25)
	add_child(authored)
	await get_tree().process_frame

	level.tree_scatter_density = 1.0
	level.exit_forest_density = 0.85
	level.apply_map_interior(interior, dungeon, exit_a)
	await get_tree().process_frame

	var plan: Dictionary = level.exit_forest_plan()
	var pocket: Array = plan.get("pocket", [])
	var egress: Array = plan.get("egress", [])
	var placeable: Array = plan.get("placeable", [])
	if pocket.is_empty():
		_fail("US-032: expected non-empty exit forest pocket")
		return false
	if egress.is_empty() or not egress.has(exit_a):
		_fail("US-032: egress must include exit door cell")
		return false
	var landing: Vector2i = plan.get("landing", DungeonGrid.SENTINEL)
	if landing == DungeonGrid.SENTINEL or not egress.has(landing):
		_fail("US-032: egress must include an outside landing")
		return false
	if dungeon.has_point(landing):
		_fail("US-032: landing must be outside dungeon")
		return false

	for cell in pocket:
		if dungeon.has_point(cell):
			_fail("US-032: pocket cell on dungeon %s" % cell)
			return false
		if not level.map_bounds.is_interior_cell(cell):
			_fail("US-032: pocket cell not interior %s" % cell)
			return false
		if level.map_bounds.is_cliff_cell(cell):
			_fail("US-032: pocket cell on cliff %s" % cell)
			return false
		if level.map_bounds.west_spawn_strip_cells(dungeon).has(cell):
			_fail("US-032: pocket cell on west strip %s" % cell)
			return false

	var forest_parent: Node = level.get_node_or_null("ExitForestTrees")
	if forest_parent == null:
		_fail("US-032: ExitForestTrees missing")
		return false

	var forest_tree_cells: Dictionary = {}
	var skill_count := 0
	var skill_cell := DungeonGrid.SENTINEL
	for child in forest_parent.get_children():
		if not (child is Node2D):
			continue
		var cell: Vector2i = DungeonGrid.from_world((child as Node2D).position)
		if child.is_in_group("exit_forest_skill_trees") or child.is_in_group("skill_trees"):
			skill_count += 1
			skill_cell = cell
			continue
		if not child.is_in_group("exit_forest_trees"):
			_fail("US-032: unexpected ExitForestTrees child %s" % child.name)
			return false
		if dungeon.has_point(cell):
			_fail("US-032: forest tree on dungeon %s" % cell)
			return false
		if egress.has(cell):
			_fail("US-032: forest tree on egress %s" % cell)
			return false
		if not pocket.has(cell):
			_fail("US-032: forest tree outside pocket %s" % cell)
			return false
		forest_tree_cells[cell] = true

	if forest_tree_cells.is_empty():
		_fail("US-032: expected dense forest trees")
		return false

	# Dense >> US-024 8%: most placeable non-skill cells should be filled.
	var placeable_for_trees: int = placeable.size()
	if skill_cell != DungeonGrid.SENTINEL and placeable.has(skill_cell):
		placeable_for_trees = maxi(placeable_for_trees - 1, 0)
	var ratio: float = 0.0
	if placeable_for_trees > 0:
		ratio = float(forest_tree_cells.size()) / float(placeable_for_trees)
	if ratio < 0.5:
		_fail("US-032: forest density %s too low (want dense >> 8%%)" % ratio)
		return false

	var scene_skills: Array = get_tree().get_nodes_in_group("skill_trees")
	if scene_skills.size() != 1:
		_fail("US-032: expected exactly one SkillTree, got %d" % scene_skills.size())
		return false
	if skill_count != 1:
		_fail("US-032: ExitForestTrees skill count %d" % skill_count)
		return false
	if skill_cell == DungeonGrid.SENTINEL or not pocket.has(skill_cell) or egress.has(skill_cell):
		_fail("US-032: SkillTree cell invalid %s" % skill_cell)
		return false
	if is_instance_valid(authored) and authored.is_inside_tree():
		_fail("US-032: authored SkillTree was not superseded")
		return false

	for cell in egress:
		if forest_tree_cells.has(cell) or cell == skill_cell:
			_fail("US-032: egress cell occupied %s" % cell)
			return false

	# T005: sparse eligible ∩ pocket == ∅
	var sparse: Array[Vector2i] = level.tree_scatter_eligible_cells()
	for cell in pocket:
		if sparse.has(cell):
			_fail("US-032: sparse eligible intersects pocket at %s" % cell)
			return false
	var scattered: Node = level.get_node_or_null("ScatteredTrees")
	var sparse_outside := 0
	if scattered:
		for child in scattered.get_children():
			var cell: Vector2i = DungeonGrid.from_world(child.position)
			if pocket.has(cell):
				_fail("US-032: sparse tree inside pocket %s" % cell)
				return false
			sparse_outside += 1
	if sparse_outside < 1:
		_fail("US-032: expected sparse trees outside pocket")
		return false

	# Peer seed match
	var other := Node2D.new()
	other.set_script(load("res://_globals/level_manager.gd"))
	add_child(other)
	await get_tree().process_frame
	other.tree_scatter_density = 1.0
	other.exit_forest_density = 0.85
	other.apply_map_interior(interior, dungeon, exit_a)
	await get_tree().process_frame
	var a_sig: Array[int] = _forest_signature(forest_parent)
	var b_sig: Array[int] = _forest_signature(other.get_node("ExitForestTrees"))
	if a_sig != b_sig:
		_fail("US-032: exit forest seed must match across peers")
		return false

	# T004: fake exit move — clear old, place new
	var old_pocket: Array = pocket.duplicate()
	level.apply_map_interior(interior, dungeon, exit_b)
	await get_tree().process_frame
	var plan_b: Dictionary = level.exit_forest_plan()
	var pocket_b: Array = plan_b.get("pocket", [])
	var egress_b: Array = plan_b.get("egress", [])
	if pocket_b.is_empty():
		_fail("US-032: pocket empty after exit move")
		return false
	var occupied_after: Dictionary = {}
	var forest_after: Dictionary = {}
	var skill_after := 0
	var skill_cell_after := DungeonGrid.SENTINEL
	for child in forest_parent.get_children():
		var cell: Vector2i = DungeonGrid.from_world(child.position)
		occupied_after[cell] = true
		if child.is_in_group("exit_forest_skill_trees") or child.is_in_group("skill_trees"):
			skill_after += 1
			skill_cell_after = cell
		elif child.is_in_group("exit_forest_trees"):
			forest_after[cell] = true
	if skill_after != 1:
		_fail("US-032: after exit move SkillTree count %d" % skill_after)
		return false
	if skill_cell_after == DungeonGrid.SENTINEL or not pocket_b.has(skill_cell_after):
		_fail("US-032: after exit move SkillTree not in new pocket %s" % skill_cell_after)
		return false
	if egress_b.has(skill_cell_after):
		_fail("US-032: after exit move SkillTree on new egress %s" % skill_cell_after)
		return false
	for cell in egress_b:
		if forest_after.has(cell) or cell == skill_cell_after:
			_fail("US-032: after exit move egress cell occupied %s" % cell)
			return false
	for cell in old_pocket:
		if occupied_after.has(cell) and not pocket_b.has(cell):
			_fail("US-032: orphan forest at old pocket cell %s" % cell)
			return false
	var any_new := false
	for cell in pocket_b:
		if occupied_after.has(cell):
			any_new = true
			break
	if not any_new:
		_fail("US-032: no forest in new pocket after exit move")
		return false

	level.queue_free()
	other.queue_free()
	await get_tree().process_frame
	return true


func _run_room_center_and_density_suite() -> bool:
	# Live geometry: exit room center is ~3 cells inside dungeon AABB (radius 2 + wall).
	var dungeon := Rect2i(10, 5, 20, 12)
	var interior: Rect2i = MapBounds.interior_from_dungeon_aabb(dungeon)
	var exit_center := Vector2i(13, 10)

	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	add_child(level)
	await get_tree().process_frame

	# Confused knob: density=10 must mean max dense (1.0), not empty/break.
	level.tree_scatter_density = 0.0
	level.exit_forest_density = 10.0
	level.apply_map_interior(interior, dungeon, exit_center)
	await get_tree().process_frame

	var plan: Dictionary = level.exit_forest_plan()
	var pocket: Array = plan.get("pocket", [])
	var placeable: Array = plan.get("placeable", [])
	var landing: Vector2i = plan.get("landing", DungeonGrid.SENTINEL)
	print("US-032 diag room-center: pocket=%d placeable=%d egress=%d landing=%s" % [
		pocket.size(), placeable.size(), (plan.get("egress", []) as Array).size(), str(landing)
	])
	if landing == DungeonGrid.SENTINEL:
		_fail("US-032: room-center exit must project an outside landing")
		return false
	if dungeon.has_point(landing):
		_fail("US-032: projected landing still in dungeon %s" % landing)
		return false
	if pocket.is_empty() or placeable.is_empty():
		_fail("US-032: room-center exit pocket/placeable empty (live bug regress)")
		return false

	var forest_parent: Node = level.get_node_or_null("ExitForestTrees")
	if forest_parent == null:
		_fail("US-032: ExitForestTrees missing for room-center")
		return false
	var tree_n := 0
	var skill_n := 0
	for child in forest_parent.get_children():
		if child.is_in_group("exit_forest_skill_trees") or child.is_in_group("skill_trees"):
			skill_n += 1
		elif child.is_in_group("exit_forest_trees"):
			tree_n += 1
	if tree_n < 1:
		_fail("US-032: room-center density=10 placed no trees")
		return false
	if skill_n != 1:
		_fail("US-032: room-center SkillTree count %d" % skill_n)
		return false
	# Max dense: every placeable non-skill cell filled.
	var expected_trees: int = placeable.size() - 1
	if expected_trees < 1:
		expected_trees = placeable.size()
	if tree_n < maxi(expected_trees, 1):
		_fail("US-032: density=10 should max-fill; trees=%d placeable=%d" % [tree_n, placeable.size()])
		return false

	level.queue_free()
	await get_tree().process_frame
	return true


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)


func _forest_signature(parent: Node) -> Array[int]:
	var sig: Array[int] = []
	if parent == null:
		return sig
	for child in parent.get_children():
		if not (child is Node2D):
			continue
		var cell: Vector2i = DungeonGrid.from_world((child as Node2D).position)
		var kind := 0
		if child.is_in_group("exit_forest_skill_trees") or child.is_in_group("skill_trees"):
			kind = 2
		elif child.is_in_group("exit_forest_trees"):
			kind = 1
			if "tree_type" in child:
				kind = 10 + int(child.tree_type)
		sig.append(cell.x * 100000 + cell.y * 100 + kind)
	sig.sort()
	return sig
