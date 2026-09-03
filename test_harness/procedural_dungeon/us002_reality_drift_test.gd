extends Node

func _ready() -> void:
	PlayerManager.reality_level = 0
	DmManager.fantasy_level = 0
	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	level.add_to_group("level_manager")
	add_child(level)
	await _flush_zones()

	var interior := Rect2i(0, 0, 16, 10)
	var dungeon := Rect2i(8, 2, 8, 6)
	level.apply_map_interior(interior, dungeon)
	await _flush_zones()
	level.rebuild_outside_fill()
	await _flush_zones()

	var drift: RealityTileDrift = level.get_node_or_null("RealityTileDrift")
	if drift == null:
		push_error("US-002: RealityTileDrift missing")
		get_tree().quit(1)
		return
	drift.delay_min = 0.0
	drift.delay_max = 0.0
	drift.set_physics_process(false)
	drift.clear_schedules()

	var reality: RealityZone = load("res://zones/reality_zone.tscn").instantiate()
	reality.add_to_group("RealityZone")
	add_child(reality)
	drift.set_physics_process(false)
	await _flush_zones()
	drift.set_physics_process(false)

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

	if ResourceLoader.exists("res://sprites/reality_drift_puff.png") and not _has_puff(level):
		push_error("US-002 T005: convert puff missing")
		get_tree().quit(1)
		return

	if not _snapshot_matches(level, home_cell, home_kind, home_variety, int(OutsideTile.ElementPresentation.REALITY)):
		push_error("US-002 T006: late-join snapshot missing current Reality presentation")
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

	# US-025 T005: already-converted Reality art must snap Neutral when unclaimed.
	var leak_tile: OutsideTile = _outside_at(east_cell)
	if leak_tile == null:
		push_error("US-025 T005: Reality leak cell missing")
		get_tree().quit(1)
		return
	var leak_kind: int = int(leak_tile.ground_kind)
	var leak_variety: int = int(leak_tile.variety)
	var leak_pocket_id: int = reality.spawn_pocket(east_cell, Vector2i(2, 2), 8.0)
	if leak_pocket_id < 0:
		push_error("US-025 T005: Reality leak pocket spawn failed")
		get_tree().quit(1)
		return
	leak_tile.element_presentation = OutsideTile.ElementPresentation.REALITY
	drift.set_physics_process(false)
	if not reality.expire_pocket(leak_pocket_id):
		push_error("US-025 T005: Reality leak pocket expire failed")
		get_tree().quit(1)
		return
	drift.set_physics_process(false)
	await _flush_zones()
	drift.set_physics_process(false)
	leak_tile = _outside_at(east_cell)
	if leak_tile == null or leak_tile.element_presentation == OutsideTile.ElementPresentation.REALITY:
		push_error("US-025 T005: unclaimed cell must not remain Reality after claim loss")
		get_tree().quit(1)
		return
	if leak_tile.element_presentation != OutsideTile.ElementPresentation.NEUTRAL:
		push_error("US-025 T005: unclaimed cell must snap Neutral, got %s" % leak_tile.element_presentation)
		get_tree().quit(1)
		return
	if int(leak_tile.ground_kind) != leak_kind or int(leak_tile.variety) != leak_variety:
		push_error("US-025 T005: Reality snap must not change kind or variety")
		get_tree().quit(1)
		return
	if not _snapshot_matches(level, east_cell, leak_kind, leak_variety, int(OutsideTile.ElementPresentation.NEUTRAL)):
		push_error("US-025 T005: snapshot must reflect Neutral after Reality strip")
		get_tree().quit(1)
		return

	drift.set_physics_process(false)
	var fantasy: FantasyZone = load("res://zones/fantasy_zone.tscn").instantiate()
	add_child(fantasy)
	await _flush_zones()
	PlayerManager.reality_level = 8
	DmManager.fantasy_level = 8
	reality.on_level_changed(8)
	fantasy.on_level_changed(8)
	await _flush_zones()
	if Zone.homes_occupy_same_cell(reality.home_rect, fantasy.home_rect):
		push_error("US-025 T001: Reality and Fantasy homes must not overlap after equal bump")
		get_tree().quit(1)
		return
	if not reality.home_rect.has_point(home_cell):
		push_error("US-002 T004: west Reality home cell must remain in Reality after equal resolve")
		get_tree().quit(1)
		return
	if fantasy.home_rect.has_point(home_cell):
		push_error("US-025 T001: west Reality home cell must not also be Fantasy home")
		get_tree().quit(1)
		return
	if not drift.is_reality_drift_eligible(home_cell):
		push_error("US-002 T004: exclusive Reality home cell must be Reality-drift eligible")
		get_tree().quit(1)
		return
	PlayerManager.reality_level = 12
	reality.on_level_changed(12)
	await _flush_zones()
	if Zone.homes_occupy_same_cell(reality.home_rect, fantasy.home_rect):
		push_error("US-025 T002: homes must stay disjoint after higher Reality Level")
		get_tree().quit(1)
		return
	if not drift.is_reality_drift_eligible(home_cell):
		push_error("US-002 T004: higher Reality Level must keep the west home cell")
		get_tree().quit(1)
		return

	var fantasy_pocket_id: int = fantasy.spawn_pocket(home_cell, Vector2i(2, 2), 8.0)
	if fantasy_pocket_id < 0:
		push_error("US-002 T004: Fantasy pocket spawn failed")
		get_tree().quit(1)
		return
	if drift.is_reality_drift_eligible(home_cell):
		push_error("US-002 T004: Fantasy pocket must block Reality drift")
		get_tree().quit(1)
		return
	if not fantasy.expire_pocket(fantasy_pocket_id):
		push_error("US-002 T004: Fantasy pocket expire failed")
		get_tree().quit(1)
		return
	if not drift.is_reality_drift_eligible(home_cell):
		push_error("US-002 T004: Reality home must win again after Fantasy pocket expires")
		get_tree().quit(1)
		return

	var reality_pocket_id: int = reality.spawn_pocket(east_cell, Vector2i(2, 2), 8.0)
	if reality_pocket_id < 0:
		push_error("US-002 T004: Reality pocket over Fantasy grass failed")
		get_tree().quit(1)
		return
	if not drift.is_reality_drift_eligible(east_cell):
		push_error("US-002 T004: Reality pocket must schedule Reality drift")
		get_tree().quit(1)
		return
	if not reality.expire_pocket(reality_pocket_id):
		push_error("US-002 T004: Reality pocket expire failed")
		get_tree().quit(1)
		return
	if drift.is_reality_drift_eligible(east_cell):
		push_error("US-002 T004: expired Reality pocket must drop Reality eligibility")
		get_tree().quit(1)
		return

	PlayerManager.reality_level = 0
	DmManager.fantasy_level = 0
	print("US-002 Reality tile drift test passed")
	get_tree().quit(0)

func _flush_zones() -> void:
	await get_tree().process_frame
	ZoneDriftClaim.flush_pending_work()

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

func _has_puff(level: Node) -> bool:
	for child in level.get_children():
		if child is AnimatedSprite2D and str(child.name).find("Puff") >= 0:
			return true
	return false

func _snapshot_matches(level: Node, cell: Vector2i, kind: int, variety: int, presentation: int) -> bool:
	if not level.has_method("build_map_sync_payload"):
		return false
	var payload: Dictionary = level.build_map_sync_payload()
	for item in payload.get("out", []):
		if typeof(item) != TYPE_DICTIONARY:
			continue
		if int(item.get("x", 0)) != cell.x or int(item.get("y", 0)) != cell.y:
			continue
		return int(item.get("k", -1)) == kind and int(item.get("v", -1)) == variety and int(item.get("p", -1)) == presentation
	return false
