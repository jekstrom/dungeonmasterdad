extends Node

## US-033 headless harness: shared vs isolated reveal, visit radius, markers,
## M toggle, late-join snapshot, T010 trees/mines/walls. Exact pass print required.


func _ready() -> void:
	if not await _run_suite():
		return
	print("US-033 mini-map test passed")
	get_tree().quit(0)


func _run_suite() -> bool:
	var reveal: Node = get_node_or_null("/root/MinimapReveal")
	if reveal == null:
		return _fail("US-033: MinimapReveal autoload missing")

	reveal.reset_reveals()

	# --- Visit radius Chebyshev ≤3 sticky (T003/T004) ---
	var center := Vector2i(10, 10)
	var added: int = int(reveal.apply_visit_at(false, center))
	var expect_brush: int = int(reveal.brush_cell_count())
	if added != expect_brush:
		return _fail("US-033: PP visit brush size %d want %d" % [added, expect_brush])
	if not reveal.is_pp_revealed(Vector2i(13, 10)):
		return _fail("US-033: Chebyshev edge (13,10) must be revealed")
	if reveal.is_pp_revealed(Vector2i(14, 10)):
		return _fail("US-033: outside radius (14,10) must stay fogged")
	if reveal.is_dm_revealed(center):
		return _fail("US-033: PP visit must not write dm_private")

	if int(reveal.apply_visit_at(false, center)) != 0:
		return _fail("US-033: sticky reveal must not re-add cells")

	var dm_center := Vector2i(30, 30)
	reveal.apply_visit_at(true, dm_center)
	if reveal.is_pp_revealed(dm_center):
		return _fail("US-033: DM visit must not write pp_shared")
	if not reveal.is_dm_revealed(Vector2i(33, 30)):
		return _fail("US-033: DM Chebyshev edge must reveal")
	if reveal.is_dm_revealed(center):
		return _fail("US-033: DM set must stay isolated from PP cells")

	var pp_count: int = reveal.pp_shared.size()
	if pp_count != expect_brush:
		return _fail("US-033: shared PP count mismatch")

	# --- Late-join snapshot (T007) ---
	var packed_pp: PackedInt32Array = reveal.snapshot_pp()
	var packed_dm: PackedInt32Array = reveal.snapshot_dm()
	if packed_pp.is_empty() or packed_dm.is_empty():
		return _fail("US-033: snapshots must be non-empty after visits")

	var joiner_pp: Dictionary = {}
	reveal.decode_cells(packed_pp, joiner_pp)
	if joiner_pp.size() != reveal.pp_shared.size():
		return _fail("US-033: PP late-join snapshot size mismatch")
	for cell in reveal.pp_shared.keys():
		if not joiner_pp.has(cell):
			return _fail("US-033: PP late-join missing cell %s" % cell)

	reveal.rpc_snapshot_pp(PackedInt32Array())
	if reveal.pp_shared.size() != 0:
		return _fail("US-033: wipe failed")
	reveal.rpc_snapshot_pp(packed_pp)
	if reveal.pp_shared.size() != pp_count:
		return _fail("US-033: apply snapshot did not restore PP set")

	reveal.rpc_snapshot_dm(PackedInt32Array())
	reveal.rpc_snapshot_dm(packed_dm)
	if not reveal.is_dm_revealed(dm_center):
		return _fail("US-033: DM late-join snapshot must restore dm_private")
	if reveal.is_pp_revealed(dm_center):
		return _fail("US-033: restoring DM snapshot must not leak into PP")

	# Marker helpers
	if not reveal.should_show_pp_marker(false, Vector2i(1, 1)):
		return _fail("US-033: PP map must always show PP markers")
	if reveal.should_show_dm_marker(false, Vector2i(99, 99)):
		return _fail("US-033: PP map must fog-gate DM marker")
	if not reveal.should_show_dm_marker(true, Vector2i(99, 99)):
		return _fail("US-033: DM map must always show DM marker")

	# --- Widget shell + M toggle (T001) + grid paint (T002) ---
	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	level.add_to_group("level_manager")
	add_child(level)
	await get_tree().process_frame
	var interior := Rect2i(0, 0, 16, 10)
	level.apply_map_interior(interior, Rect2i(8, 2, 8, 6), Vector2i(8, 5))
	await get_tree().process_frame

	var widget: Control = load("res://gui/minimap/minimap_widget.tscn").instantiate() as Control
	var hud := CanvasLayer.new()
	hud.visible = true
	add_child(hud)
	hud.add_child(widget)
	await get_tree().process_frame
	if widget.has_method("configure"):
		widget.configure(false)
	await get_tree().process_frame

	if not widget.visible:
		return _fail("US-033: mini-map must be visible by default")
	var frame: TextureRect = widget.get_node_or_null("Frame") as TextureRect
	if frame == null or frame.texture == null:
		return _fail("US-033: Art frame TextureRect missing")
	if widget.get_node_or_null("MapView") == null:
		return _fail("US-033: MapView missing")

	if not widget.has_method("toggle_map"):
		return _fail("US-033: toggle_map missing")
	widget.toggle_map()
	if widget.visible:
		return _fail("US-033: M toggle must hide")
	widget.toggle_map()
	if not widget.visible:
		return _fail("US-033: M toggle must show again")

	if widget.size.x <= 0 or widget.size.y <= 0:
		return _fail("US-033: widget size invalid")
	if level.map_bounds.get_interior() != interior:
		return _fail("US-033: interior bounds not committed for paint")

	# Interior-clipped visit near edge
	reveal.reset_reveals()
	var edge := Vector2i(0, 0)
	var clipped: int = int(reveal.apply_visit_at(false, edge))
	if clipped <= 0 or clipped > expect_brush:
		return _fail("US-033: interior-clipped brush invalid %d" % clipped)
	if reveal.is_pp_revealed(Vector2i(-1, 0)):
		return _fail("US-033: outside-interior cell must not reveal")

	# Actors / buildings
	reveal.reset_reveals()
	var pp_a := _make_actor("PP_A", ["players"], Vector2i(4, 4), 10)
	var pp_b := _make_actor("PP_B", ["players"], Vector2i(5, 5), 10)
	var dm := _make_actor("dm", ["dm"], Vector2i(12, 8), 10)
	add_child(pp_a)
	add_child(pp_b)
	add_child(dm)
	await get_tree().process_frame

	if not reveal.should_show_pp_marker(false, DungeonGrid.from_world(pp_a.global_position)):
		return _fail("US-033: ally-always policy broken")
	var dm_cell: Vector2i = DungeonGrid.from_world(dm.global_position)
	if reveal.should_show_dm_marker(false, dm_cell):
		return _fail("US-033: DM pip must be fog-gated on PP map before reveal")
	reveal.apply_visit_at(false, dm_cell)
	if not reveal.should_show_dm_marker(false, dm_cell):
		return _fail("US-033: DM pip must appear once revealed on PP map")

	pp_b.set("hitpoints", 0)
	if int(pp_b.get("hitpoints")) > 0:
		return _fail("US-033: failed to zero PP hitpoints")

	var building := Node2D.new()
	building.add_to_group("buildings")
	var bscript := GDScript.new()
	bscript.source_code = "extends Node2D\nvar is_ghost := false\nvar destroyed := false\n"
	bscript.reload()
	building.set_script(bscript)
	building.position = DungeonGrid.to_world_center(Vector2i(2, 2))
	add_child(building)
	var bcell := DungeonGrid.from_world(building.global_position)
	reveal.reset_reveals()
	if reveal.is_pp_revealed(bcell):
		return _fail("US-033: building cell must start fogged after reset")
	reveal.apply_visit_at(false, bcell)
	if not reveal.is_pp_revealed(bcell):
		return _fail("US-033: building cell must reveal for marker")

	var pp_hud: Node = get_node_or_null("/root/PlayerHud")
	var dm_hud: Node = get_node_or_null("/root/DmHud")
	if pp_hud == null or dm_hud == null:
		return _fail("US-033: PlayerHud/DmHud autoloads missing")
	if pp_hud.get_node_or_null("MinimapWidget") == null:
		return _fail("US-033: PlayerHud missing MinimapWidget")
	if dm_hud.get_node_or_null("MinimapWidget") == null:
		return _fail("US-033: DmHud missing MinimapWidget")

	# --- T010: living trees, mines, dungeon walls on revealed cells only ---
	# Down leftover actors so host tick does not re-brush reveal mid-assert.
	for actor in [pp_a, pp_b, dm]:
		if is_instance_valid(actor) and "hitpoints" in actor:
			actor.set("hitpoints", 0)
	if not await _assert_t010_world_content(reveal, widget, interior):
		return false

	return true


func _assert_t010_world_content(reveal: Node, widget: Control, interior: Rect2i) -> bool:
	if not widget.has_method("collect_revealed_tree_cells"):
		return _fail("US-033 T010: collect_revealed_tree_cells missing")
	if not widget.has_method("collect_revealed_mine_cells"):
		return _fail("US-033 T010: collect_revealed_mine_cells missing")
	if not widget.has_method("collect_revealed_wall_cells"):
		return _fail("US-033 T010: collect_revealed_wall_cells missing")

	if not ResourceLoader.exists("res://gui/minimap/tree_pip.png"):
		return _fail("US-033 T010: tree_pip.png missing")
	if not ResourceLoader.exists("res://gui/minimap/mine_pip.png"):
		return _fail("US-033 T010: mine_pip.png missing")
	if not ResourceLoader.exists("res://gui/minimap/dungeon_wall_wash.png"):
		return _fail("US-033 T010: dungeon_wall_wash.png missing")

	# Drop level-spawned doodads so cell asserts are not polluted by scatter/exit forest.
	var doomed: Array = []
	for group_name in ["scattered_trees", "exit_forest_trees", "scattered_mines", "mines", "wall"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if is_instance_valid(node) and not doomed.has(node):
				doomed.append(node)
	for node in doomed:
		node.free()
	await get_tree().process_frame

	reveal.reset_reveals()

	var living := _make_content_node("tree_living", ["scattered_trees"], Vector2i(3, 3), {
		"is_stump": false,
	})
	var stump := _make_content_node("tree_stump", ["scattered_trees"], Vector2i(3, 4), {
		"is_stump": true,
	})
	var exit_tree := _make_content_node("tree_exit", ["exit_forest_trees"], Vector2i(6, 3), {
		"is_stump": false,
	})
	var skill_tree := _make_content_node("skill_tree", ["skill_trees", "exit_forest_skill_trees"], Vector2i(6, 5), {})
	var mine := _make_content_node("mine_active", ["scattered_mines", "mines"], Vector2i(7, 4), {
		"is_depleted": false,
	})
	var mine_dead := _make_content_node("mine_dead", ["scattered_mines", "mines"], Vector2i(7, 5), {
		"is_depleted": true,
	})
	# Real generated walls use generated_dungeon_tiles + wall_type; group "wall" also accepted.
	var wall := _make_content_node("dungeon_wall", ["generated_dungeon_tiles"], Vector2i(9, 4), {
		"wall_type": 1,
	})
	var fog_tree := _make_content_node("tree_fogged", ["scattered_trees"], Vector2i(14, 8), {
		"is_stump": false,
	})
	var fog_mine := _make_content_node("mine_fogged", ["scattered_mines", "mines"], Vector2i(14, 7), {
		"is_depleted": false,
	})
	var fog_wall := _make_content_node("wall_fogged", ["generated_dungeon_tiles"], Vector2i(15, 8), {
		"wall_type": 2,
	})
	for n in [living, stump, exit_tree, skill_tree, mine, mine_dead, wall, fog_tree, fog_mine, fog_wall]:
		add_child(n)
	await get_tree().process_frame
	# Clear any tick reveals from prior living movers; actors are downed by caller.
	reveal.reset_reveals()

	var living_cell: Vector2i = DungeonGrid.from_world(living.global_position)
	var stump_cell: Vector2i = DungeonGrid.from_world(stump.global_position)
	var exit_cell: Vector2i = DungeonGrid.from_world(exit_tree.global_position)
	var skill_cell: Vector2i = DungeonGrid.from_world(skill_tree.global_position)
	var mine_cell: Vector2i = DungeonGrid.from_world(mine.global_position)
	var mine_dead_cell: Vector2i = DungeonGrid.from_world(mine_dead.global_position)
	var wall_cell: Vector2i = DungeonGrid.from_world(wall.global_position)
	var fog_tree_cell: Vector2i = DungeonGrid.from_world(fog_tree.global_position)
	var fog_mine_cell: Vector2i = DungeonGrid.from_world(fog_mine.global_position)
	var fog_wall_cell: Vector2i = DungeonGrid.from_world(fog_wall.global_position)

	# Fogged: nothing listed
	var trees_fog = widget.collect_revealed_tree_cells(reveal, interior)
	var mines_fog = widget.collect_revealed_mine_cells(reveal, interior)
	var walls_fog = widget.collect_revealed_wall_cells(reveal, interior)
	if living_cell in trees_fog or exit_cell in trees_fog or fog_tree_cell in trees_fog:
		return _fail("US-033 T010: tree pips must hide while fogged")
	if stump_cell in trees_fog:
		return _fail("US-033 T010: stump must stay hidden (default)")
	if mine_cell in mines_fog or fog_mine_cell in mines_fog:
		return _fail("US-033 T010: mine pips must hide while fogged")
	if wall_cell in walls_fog or fog_wall_cell in walls_fog:
		return _fail("US-033 T010: wall tint must not leak through fog")

	# Reveal living tree / exit tree / skill tree / mine / wall — leave fog_* unrevealed
	for cell in [living_cell, stump_cell, exit_cell, skill_cell, mine_cell, mine_dead_cell, wall_cell]:
		reveal.apply_visit_at(false, cell)

	var trees = widget.collect_revealed_tree_cells(reveal, interior)
	var mines = widget.collect_revealed_mine_cells(reveal, interior)
	var walls = widget.collect_revealed_wall_cells(reveal, interior)

	if living_cell not in trees:
		return _fail("US-033 T010: living scattered tree must show when revealed")
	if exit_cell not in trees:
		return _fail("US-033 T010: exit-forest living tree must show when revealed")
	if skill_cell not in trees:
		return _fail("US-033 T010: skill tree must show when revealed")
	if stump_cell in trees:
		return _fail("US-033 T010: stump must be omitted by default")
	if fog_tree_cell in trees:
		return _fail("US-033 T010: fogged tree must stay hidden after other reveals")
	if mine_cell not in mines:
		return _fail("US-033 T010: active mine must show when revealed")
	if mine_dead_cell in mines:
		return _fail("US-033 T010: depleted mine must clear")
	if fog_mine_cell in mines:
		return _fail("US-033 T010: fogged mine must stay hidden")
	if wall_cell not in walls:
		return _fail("US-033 T010: revealed dungeon wall must tint")
	if fog_wall_cell in walls:
		return _fail("US-033 T010: unrevealed wall must stay fogged (no silhouette leak)")

	# Reveal sets unchanged in rules: PP visit still does not write DM, and vice versa
	if reveal.is_dm_revealed(living_cell):
		return _fail("US-033 T010: tree/mine/wall paint must not merge into dm_reveal")
	var dm_only := Vector2i(1, 8)
	reveal.apply_visit_at(true, dm_only)
	if reveal.is_pp_revealed(dm_only):
		return _fail("US-033 T010: DM visit must not write pp_shared")

	# Optional stump toggle still fog-gates
	if "show_tree_stumps" in widget:
		widget.set("show_tree_stumps", true)
		var trees_stump = widget.collect_revealed_tree_cells(reveal, interior)
		if stump_cell not in trees_stump:
			return _fail("US-033 T010: show_tree_stumps=true should include stump when revealed")
		widget.set("show_tree_stumps", false)

	return true


func _make_content_node(node_name: String, groups: Array, cell: Vector2i, props: Dictionary) -> Node2D:
	var node := Node2D.new()
	node.name = node_name
	for g in groups:
		node.add_to_group(str(g))
	var lines: PackedStringArray = PackedStringArray(["extends Node2D"])
	for key in props.keys():
		var val = props[key]
		if typeof(val) == TYPE_BOOL:
			lines.append("var %s := %s" % [key, "true" if val else "false"])
		elif typeof(val) == TYPE_INT:
			lines.append("var %s := %d" % [key, int(val)])
		else:
			lines.append("var %s = %s" % [key, str(val)])
	var script := GDScript.new()
	script.source_code = "\n".join(lines) + "\n"
	script.reload()
	node.set_script(script)
	node.position = DungeonGrid.to_world_center(cell)
	return node


func _make_actor(actor_name: String, groups: Array, cell: Vector2i, hp: int) -> Node2D:
	var node := Node2D.new()
	node.name = actor_name
	for g in groups:
		node.add_to_group(str(g))
	var script := GDScript.new()
	script.source_code = "extends Node2D\nvar hitpoints := %d\nfunc is_downed() -> bool:\n\treturn hitpoints <= 0\n" % hp
	script.reload()
	node.set_script(script)
	node.position = DungeonGrid.to_world_center(cell)
	return node


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
