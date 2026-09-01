extends Node

## US-032 headless harness: dense exit forest + SkillTree, egress clear, sparse exclusion, rebuild.

func _ready() -> void:
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
	level.exit_forest_density = 0.78
	level.apply_map_interior(interior, dungeon, exit_a)
	await get_tree().process_frame

	var plan: Dictionary = level.exit_forest_plan()
	var pocket: Array = plan.get("pocket", [])
	var egress: Array = plan.get("egress", [])
	var placeable: Array = plan.get("placeable", [])
	if pocket.is_empty():
		_fail("US-032: expected non-empty exit forest pocket")
		return
	if egress.is_empty() or not egress.has(exit_a):
		_fail("US-032: egress must include exit door cell")
		return
	var landing: Vector2i = plan.get("landing", DungeonGrid.SENTINEL)
	if landing == DungeonGrid.SENTINEL or not egress.has(landing):
		_fail("US-032: egress must include an outside landing")
		return
	if dungeon.has_point(landing):
		_fail("US-032: landing must be outside dungeon")
		return

	for cell in pocket:
		if dungeon.has_point(cell):
			_fail("US-032: pocket cell on dungeon %s" % cell)
			return
		if not level.map_bounds.is_interior_cell(cell):
			_fail("US-032: pocket cell not interior %s" % cell)
			return
		if level.map_bounds.is_cliff_cell(cell):
			_fail("US-032: pocket cell on cliff %s" % cell)
			return
		if level.map_bounds.west_spawn_strip_cells(dungeon).has(cell):
			_fail("US-032: pocket cell on west strip %s" % cell)
			return

	var forest_parent: Node = level.get_node_or_null("ExitForestTrees")
	if forest_parent == null:
		_fail("US-032: ExitForestTrees missing")
		return

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
			return
		if dungeon.has_point(cell):
			_fail("US-032: forest tree on dungeon %s" % cell)
			return
		if egress.has(cell):
			_fail("US-032: forest tree on egress %s" % cell)
			return
		if not pocket.has(cell):
			_fail("US-032: forest tree outside pocket %s" % cell)
			return
		forest_tree_cells[cell] = true

	if forest_tree_cells.is_empty():
		_fail("US-032: expected dense forest trees")
		return

	# Dense >> US-024 8%: most placeable non-skill cells should be filled.
	var placeable_for_trees: int = placeable.size()
	if skill_cell != DungeonGrid.SENTINEL and placeable.has(skill_cell):
		placeable_for_trees = maxi(placeable_for_trees - 1, 0)
	var ratio: float = 0.0
	if placeable_for_trees > 0:
		ratio = float(forest_tree_cells.size()) / float(placeable_for_trees)
	if ratio < 0.5:
		_fail("US-032: forest density %s too low (want dense >> 8%%)" % ratio)
		return

	var scene_skills: Array = get_tree().get_nodes_in_group("skill_trees")
	if scene_skills.size() != 1:
		_fail("US-032: expected exactly one SkillTree, got %d" % scene_skills.size())
		return
	if skill_count != 1:
		_fail("US-032: ExitForestTrees skill count %d" % skill_count)
		return
	if skill_cell == DungeonGrid.SENTINEL or not pocket.has(skill_cell) or egress.has(skill_cell):
		_fail("US-032: SkillTree cell invalid %s" % skill_cell)
		return
	if is_instance_valid(authored) and authored.is_inside_tree():
		_fail("US-032: authored SkillTree was not superseded")
		return

	for cell in egress:
		if forest_tree_cells.has(cell) or cell == skill_cell:
			_fail("US-032: egress cell occupied %s" % cell)
			return

	# T005: sparse eligible ∩ pocket == ∅
	var sparse: Array[Vector2i] = level.tree_scatter_eligible_cells()
	for cell in pocket:
		if sparse.has(cell):
			_fail("US-032: sparse eligible intersects pocket at %s" % cell)
			return
	# Sparse trees must not live under ExitForestTrees / ScatteredTrees on pocket.
	var scattered: Node = level.get_node_or_null("ScatteredTrees")
	if scattered:
		for child in scattered.get_children():
			var cell: Vector2i = DungeonGrid.from_world(child.position)
			if pocket.has(cell):
				_fail("US-032: sparse tree inside pocket %s" % cell)
				return

	# Peer seed match
	var other := Node2D.new()
	other.set_script(load("res://_globals/level_manager.gd"))
	add_child(other)
	await get_tree().process_frame
	other.tree_scatter_density = 1.0
	other.exit_forest_density = 0.78
	other.apply_map_interior(interior, dungeon, exit_a)
	await get_tree().process_frame
	var a_sig: Array[int] = _forest_signature(forest_parent)
	var b_sig: Array[int] = _forest_signature(other.get_node("ExitForestTrees"))
	if a_sig != b_sig:
		_fail("US-032: exit forest seed must match across peers")
		return

	# T004: fake exit move — clear old, place new
	var old_pocket: Array = pocket.duplicate()
	level.apply_map_interior(interior, dungeon, exit_b)
	await get_tree().process_frame
	var plan_b: Dictionary = level.exit_forest_plan()
	var pocket_b: Array = plan_b.get("pocket", [])
	if pocket_b.is_empty():
		_fail("US-032: pocket empty after exit move")
		return
	var occupied_after: Dictionary = {}
	var skill_after := 0
	for child in forest_parent.get_children():
		var cell: Vector2i = DungeonGrid.from_world(child.position)
		occupied_after[cell] = true
		if child.is_in_group("exit_forest_skill_trees") or child.is_in_group("skill_trees"):
			skill_after += 1
	if skill_after != 1:
		_fail("US-032: after exit move SkillTree count %d" % skill_after)
		return
	# No orphan forest keyed only to old pocket (unless overlap with new pocket).
	for cell in old_pocket:
		if occupied_after.has(cell) and not pocket_b.has(cell):
			_fail("US-032: orphan forest at old pocket cell %s" % cell)
			return
	var any_new := false
	for cell in pocket_b:
		if occupied_after.has(cell):
			any_new = true
			break
	if not any_new:
		_fail("US-032: no forest in new pocket after exit move")
		return

	print("US-032 exit forest test passed")
	get_tree().quit(0)


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
