extends Node

## US-033 headless harness: shared vs isolated reveal, visit radius, markers,
## M toggle, late-join snapshot. Exact pass print required by T009.


func _ready() -> void:
	if not await _run_suite():
		return
	print("US-033 minimap test passed")
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

	return true


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
