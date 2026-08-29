extends Node

func _ready() -> void:
	PlayerManager.reality_level = 0
	DmManager.fantasy_level = 0
	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	level.add_to_group("level_manager")
	add_child(level)
	await get_tree().process_frame

	var interior := Rect2i(0, 0, 16, 10)
	var dungeon := Rect2i(8, 2, 8, 6)
	level.apply_map_interior(interior, dungeon)
	await get_tree().process_frame
	level.rebuild_outside_fill()
	await get_tree().process_frame

	var drift: RealityTileDrift = level.get_node_or_null("RealityTileDrift")
	if drift == null:
		push_error("US-002: RealityTileDrift missing")
		get_tree().quit(1)
		return
	drift.set_physics_process(false)
	drift.delay_min = 0.0
	drift.delay_max = 0.0
	drift.clear_schedules()

	var reality: RealityZone = load("res://zones/reality_zone.tscn").instantiate()
	reality.add_to_group("RealityZone")
	add_child(reality)
	await get_tree().process_frame

	var home_cell: Vector2i = reality.home_rect.position
	var home_tile: OutsideTile = _outside_at(home_cell)
	if home_tile == null:
		push_error("US-002: Reality home must sit on an outside tile")
		get_tree().quit(1)
		return
	var home_kind: int = int(home_tile.ground_kind)
	var home_variety: int = int(home_tile.variety)
	if home_tile.element_presentation == OutsideTile.ElementPresentation.REALITY:
		push_error("US-002: home tile must start Neutral/Fantasy, not already Reality")
		get_tree().quit(1)
		return

	var east_cell := Vector2i(interior.end.x - 2, interior.position.y + 1)
	if reality.is_claimed_cell(east_cell):
		east_cell = Vector2i(interior.end.x - 1, interior.end.y - 1)
	var east_tile: OutsideTile = _outside_at(east_cell)
	if east_tile == null:
		push_error("US-002: unclaimed east outside tile missing")
		get_tree().quit(1)
		return
	var east_pres: int = int(east_tile.element_presentation)

	if not drift.is_reality_drift_eligible(home_cell):
		push_error("US-002 T001: Reality-claimed outside tile must be eligible")
		get_tree().quit(1)
		return
	if drift.is_reality_drift_eligible(dungeon.position):
		push_error("US-002 T001: dungeon cell must not be eligible")
		get_tree().quit(1)
		return
	if drift.is_reality_drift_eligible(east_cell):
		push_error("US-002 T001: unclaimed outside tile must not be eligible")
		get_tree().quit(1)
		return

	var dungeon_floor: Node2D = load("res://level/floor.tscn").instantiate() as Node2D
	dungeon_floor.position = DungeonGrid.to_world(dungeon.position)
	dungeon_floor.add_to_group("generated_dungeon_tiles")
	add_child(dungeon_floor)
	var dungeon_tex = null
	var dungeon_sprite: Sprite2D = dungeon_floor.get_node_or_null("Sprite2D")
	if dungeon_sprite:
		dungeon_tex = dungeon_sprite.texture

	var eligible_before: int = _count_eligible_not_reality(reality)
	if eligible_before < 2:
		push_error("US-002: need at least two eligible outside tiles to prove stagger")
		get_tree().quit(1)
		return

	drift.set_physics_process(true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var converted_after_two: int = _count_reality()
	if converted_after_two > 2:
		push_error("US-002: must not remap the whole rect in one frame, got %d" % converted_after_two)
		get_tree().quit(1)
		return
	if converted_after_two < 1:
		push_error("US-002: Reality home tile should start converting")
		get_tree().quit(1)
		return

	for _i in range(eligible_before + 2):
		await get_tree().physics_frame

	home_tile = _outside_at(home_cell)
	if home_tile == null or home_tile.element_presentation != OutsideTile.ElementPresentation.REALITY:
		push_error("US-002: Reality-claimed outside tile must become Reality art")
		get_tree().quit(1)
		return
	if int(home_tile.ground_kind) != home_kind:
		push_error("US-002: grass/dirt kind must not change")
		get_tree().quit(1)
		return
	if int(home_tile.variety) != home_variety:
		push_error("US-002: variety must not change")
		get_tree().quit(1)
		return
	if str(home_tile.strip_texture().resource_path).find("outside_") == -1 or str(home_tile.strip_texture().resource_path).find("_reality.png") == -1:
		push_error("US-002: Reality strip missing, got %s" % home_tile.strip_texture().resource_path)
		get_tree().quit(1)
		return

	east_tile = _outside_at(east_cell)
	if east_tile == null or int(east_tile.element_presentation) != east_pres:
		push_error("US-002: unclaimed outside tile must not convert to Reality")
		get_tree().quit(1)
		return

	if dungeon_sprite and dungeon_sprite.texture != dungeon_tex:
		push_error("US-002: dungeon floor must not drift")
		get_tree().quit(1)
		return
	if _outside_at(dungeon.position) != null:
		push_error("US-002: dungeon cell must not gain an outside tile")
		get_tree().quit(1)
		return

	drift.delay_min = 8.0
	drift.delay_max = 8.0
	var pocket_cell: Vector2i = east_cell
	var pocket_tile: OutsideTile = _outside_at(pocket_cell)
	var pocket_kind: int = int(pocket_tile.ground_kind)
	var pocket_id: int = reality.spawn_pocket(pocket_cell, Vector2i(2, 2), 8.0)
	if pocket_id < 0:
		push_error("US-002: pocket spawn failed")
		get_tree().quit(1)
		return
	await get_tree().physics_frame
	if pocket_tile.element_presentation == OutsideTile.ElementPresentation.REALITY:
		push_error("US-002: pocket tile must not convert before its delay")
		get_tree().quit(1)
		return
	if not reality.expire_pocket(pocket_id):
		push_error("US-002: pocket expire failed")
		get_tree().quit(1)
		return
	drift.delay_min = 0.0
	drift.delay_max = 0.0
	await get_tree().physics_frame
	await get_tree().physics_frame
	pocket_tile = _outside_at(pocket_cell)
	if pocket_tile == null or pocket_tile.element_presentation == OutsideTile.ElementPresentation.REALITY:
		push_error("US-002: expired pocket must cancel pending Reality drift")
		get_tree().quit(1)
		return
	if int(pocket_tile.ground_kind) != pocket_kind:
		push_error("US-002: pocket expire must not change ground kind")
		get_tree().quit(1)
		return

	PlayerManager.reality_level = 0
	print("US-002 Reality tile drift test passed")
	get_tree().quit(0)

func _outside_at(cell: Vector2i) -> OutsideTile:
	for node in get_tree().get_nodes_in_group("outside_tiles"):
		if node is OutsideTile and DungeonGrid.from_world((node as OutsideTile).position) == cell:
			return node as OutsideTile
	return null

func _count_reality() -> int:
	var n := 0
	for node in get_tree().get_nodes_in_group("outside_tiles"):
		if node is OutsideTile and (node as OutsideTile).element_presentation == OutsideTile.ElementPresentation.REALITY:
			n += 1
	return n

func _count_eligible_not_reality(reality: RealityZone) -> int:
	var n := 0
	for node in get_tree().get_nodes_in_group("outside_tiles"):
		if not (node is OutsideTile):
			continue
		var tile: OutsideTile = node
		if tile.element_presentation == OutsideTile.ElementPresentation.REALITY:
			continue
		var cell: Vector2i = DungeonGrid.from_world(tile.position)
		if not reality.is_claimed_cell(cell):
			continue
		n += 1
	return n
