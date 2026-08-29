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

	var reality_drift: RealityTileDrift = level.get_node_or_null("RealityTileDrift")
	if reality_drift:
		reality_drift.set_physics_process(false)
		reality_drift.clear_schedules()

	var drift: FantasyTileDrift = level.get_node_or_null("FantasyTileDrift")
	if drift == null:
		push_error("US-004: FantasyTileDrift missing")
		get_tree().quit(1)
		return
	drift.delay_min = 0.0
	drift.delay_max = 0.0
	drift.set_physics_process(false)
	drift.clear_schedules()

	var fantasy: FantasyZone = load("res://zones/fantasy_zone.tscn").instantiate()
	add_child(fantasy)
	DmManager.fantasy_level = 3
	fantasy.on_level_changed(3)
	drift.set_physics_process(false)
	await get_tree().process_frame
	drift.set_physics_process(false)

	var home_cell: Vector2i = _first_outside_in_home(fantasy, dungeon)
	var home_tile: OutsideTile = _outside_at(home_cell)
	if home_tile == null:
		push_error("US-004: Fantasy home must cover an outside tile after growth")
		get_tree().quit(1)
		return
	var home_kind: int = int(home_tile.ground_kind)
	var home_variety: int = int(home_tile.variety)
	if home_tile.element_presentation == OutsideTile.ElementPresentation.FANTASY:
		push_error("US-004: home tile must start Neutral/Reality, not already Fantasy")
		get_tree().quit(1)
		return

	var west_cell := Vector2i(interior.position.x, interior.position.y + 1)
	if fantasy.is_claimed_cell(west_cell):
		west_cell = Vector2i(interior.position.x, interior.end.y - 1)
	var west_tile: OutsideTile = _outside_at(west_cell)
	if west_tile == null:
		push_error("US-004: unclaimed west outside tile missing")
		get_tree().quit(1)
		return
	var west_pres: int = int(west_tile.element_presentation)

	if not drift.is_fantasy_drift_eligible(home_cell):
		push_error("US-004: Fantasy-claimed outside tile must be eligible")
		get_tree().quit(1)
		return
	if drift.is_fantasy_drift_eligible(dungeon.position):
		push_error("US-004: dungeon cell must not be eligible")
		get_tree().quit(1)
		return
	if drift.is_fantasy_drift_eligible(west_cell):
		push_error("US-004: unclaimed outside tile must not be eligible")
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

	var eligible_before: int = _count_eligible_not_fantasy(drift)
	if eligible_before < 2:
		push_error("US-004: need at least two eligible outside tiles to prove stagger")
		get_tree().quit(1)
		return

	drift.set_physics_process(true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var converted_after_two: int = _count_fantasy()
	if converted_after_two > 2:
		push_error("US-004: must not remap the whole rect in one frame, got %d" % converted_after_two)
		get_tree().quit(1)
		return
	if converted_after_two < 1:
		push_error("US-004: Fantasy home tile should start converting")
		get_tree().quit(1)
		return
	if ResourceLoader.exists("res://sprites/fantasy_drift_puff.png") and not _has_puff(level):
		push_error("US-004 T005: convert puff missing")
		get_tree().quit(1)
		return

	for _i in range(eligible_before + 2):
		await get_tree().physics_frame

	home_tile = _outside_at(home_cell)
	if home_tile == null or home_tile.element_presentation != OutsideTile.ElementPresentation.FANTASY:
		push_error("US-004: Fantasy-claimed outside tile must become Fantasy art")
		get_tree().quit(1)
		return
	if int(home_tile.ground_kind) != home_kind:
		push_error("US-004: grass/dirt kind must not change")
		get_tree().quit(1)
		return
	if int(home_tile.variety) != home_variety:
		push_error("US-004: variety must not change")
		get_tree().quit(1)
		return
	if str(home_tile.strip_texture().resource_path).find("_fantasy.png") == -1:
		push_error("US-004 T003: Fantasy strip missing, got %s" % home_tile.strip_texture().resource_path)
		get_tree().quit(1)
		return

	if not _snapshot_matches(level, home_cell, home_kind, home_variety, int(OutsideTile.ElementPresentation.FANTASY)):
		push_error("US-004 T006: late-join snapshot missing current Fantasy presentation")
		get_tree().quit(1)
		return

	west_tile = _outside_at(west_cell)
	if west_tile == null or int(west_tile.element_presentation) != west_pres:
		push_error("US-004: unclaimed outside tile must not convert to Fantasy")
		get_tree().quit(1)
		return

	if dungeon_sprite and dungeon_sprite.texture != dungeon_tex:
		push_error("US-004: dungeon floor must not drift")
		get_tree().quit(1)
		return
	if _outside_at(dungeon.position) != null:
		push_error("US-004: dungeon cell must not gain an outside tile")
		get_tree().quit(1)
		return

	drift.delay_min = 8.0
	drift.delay_max = 8.0
	var pocket_cell: Vector2i = west_cell
	var pocket_tile: OutsideTile = _outside_at(pocket_cell)
	var pocket_kind: int = int(pocket_tile.ground_kind)
	var pocket_id: int = fantasy.spawn_pocket(pocket_cell, Vector2i(2, 2), 8.0)
	if pocket_id < 0:
		push_error("US-004: Fantasy pocket spawn failed")
		get_tree().quit(1)
		return
	if not drift.is_fantasy_drift_eligible(pocket_cell):
		push_error("US-004: Fantasy pocket must make Reality-looking grass eligible")
		get_tree().quit(1)
		return
	await get_tree().physics_frame
	if pocket_tile.element_presentation == OutsideTile.ElementPresentation.FANTASY:
		push_error("US-004: pocket tile must not convert before its delay")
		get_tree().quit(1)
		return
	if not fantasy.expire_pocket(pocket_id):
		push_error("US-004: pocket expire failed")
		get_tree().quit(1)
		return
	drift.delay_min = 0.0
	drift.delay_max = 0.0
	await get_tree().physics_frame
	await get_tree().physics_frame
	pocket_tile = _outside_at(pocket_cell)
	if pocket_tile == null or pocket_tile.element_presentation == OutsideTile.ElementPresentation.FANTASY:
		push_error("US-004: expired pocket must cancel pending Fantasy drift")
		get_tree().quit(1)
		return
	if int(pocket_tile.ground_kind) != pocket_kind:
		push_error("US-004: pocket expire must not change ground kind")
		get_tree().quit(1)
		return
	if drift.is_fantasy_drift_eligible(pocket_cell):
		push_error("US-004: expired Fantasy pocket must drop Fantasy eligibility")
		get_tree().quit(1)
		return

	# US-025 T005: already-converted Fantasy art must snap Neutral when unclaimed.
	var leak_cell: Vector2i = west_cell
	var leak_tile: OutsideTile = _outside_at(leak_cell)
	if leak_tile == null:
		push_error("US-025 T005: leak cell missing")
		get_tree().quit(1)
		return
	var leak_kind: int = int(leak_tile.ground_kind)
	var leak_variety: int = int(leak_tile.variety)
	var leak_pocket_id: int = fantasy.spawn_pocket(leak_cell, Vector2i(2, 2), 8.0)
	if leak_pocket_id < 0:
		push_error("US-025 T005: leak pocket spawn failed")
		get_tree().quit(1)
		return
	leak_tile.element_presentation = OutsideTile.ElementPresentation.FANTASY
	drift.set_physics_process(false)
	if not fantasy.expire_pocket(leak_pocket_id):
		push_error("US-025 T005: leak pocket expire failed")
		get_tree().quit(1)
		return
	drift.set_physics_process(false)
	await get_tree().process_frame
	drift.set_physics_process(false)
	leak_tile = _outside_at(leak_cell)
	if leak_tile == null or leak_tile.element_presentation == OutsideTile.ElementPresentation.FANTASY:
		push_error("US-025 T005: unclaimed cell must not remain Fantasy after claim loss")
		get_tree().quit(1)
		return
	if leak_tile.element_presentation != OutsideTile.ElementPresentation.NEUTRAL:
		push_error("US-025 T005: unclaimed cell must snap Neutral, got %s" % leak_tile.element_presentation)
		get_tree().quit(1)
		return
	if int(leak_tile.ground_kind) != leak_kind or int(leak_tile.variety) != leak_variety:
		push_error("US-025 T005: snap must not change kind or variety")
		get_tree().quit(1)
		return
	if not _snapshot_matches(level, leak_cell, leak_kind, leak_variety, int(OutsideTile.ElementPresentation.NEUTRAL)):
		push_error("US-025 T005: snapshot must reflect Neutral after Fantasy strip")
		get_tree().quit(1)
		return
	west_tile = _outside_at(west_cell)
	if west_tile == null or west_tile.element_presentation == OutsideTile.ElementPresentation.FANTASY:
		push_error("US-025 T005: unclaimed west cell must never be left Fantasy")
		get_tree().quit(1)
		return

	drift.set_physics_process(false)
	if reality_drift:
		reality_drift.set_physics_process(false)
		reality_drift.clear_schedules()
	if reality_drift == null:
		push_error("US-004 T004: RealityTileDrift missing")
		get_tree().quit(1)
		return
	var reality: RealityZone = load("res://zones/reality_zone.tscn").instantiate()
	add_child(reality)
	drift.set_physics_process(false)
	reality_drift.set_physics_process(false)
	await get_tree().process_frame
	drift.set_physics_process(false)
	reality_drift.set_physics_process(false)

	if not reality.is_claimed_cell(west_cell):
		push_error("US-004 T004: west cell should be Reality home for expire-back case")
		get_tree().quit(1)
		return
	if not reality_drift.is_reality_drift_eligible(west_cell):
		push_error("US-004 T004: Reality still claiming west must be Reality-drift eligible")
		get_tree().quit(1)
		return

	var back_pocket_id: int = fantasy.spawn_pocket(west_cell, Vector2i(2, 2), 8.0)
	if back_pocket_id < 0:
		push_error("US-004 T004: Fantasy pocket over Reality grass failed")
		get_tree().quit(1)
		return
	if not drift.is_fantasy_drift_eligible(west_cell):
		push_error("US-004 T004: Fantasy pocket must override Reality home")
		get_tree().quit(1)
		return
	if reality_drift.is_reality_drift_eligible(west_cell):
		push_error("US-004 T004: Fantasy pocket must block Reality drift")
		get_tree().quit(1)
		return
	west_tile = _outside_at(west_cell)
	if west_tile == null:
		push_error("US-025 T005: Reality west tile missing before Fantasy strip")
		get_tree().quit(1)
		return
	var west_kind: int = int(west_tile.ground_kind)
	var west_variety: int = int(west_tile.variety)
	west_tile.element_presentation = OutsideTile.ElementPresentation.FANTASY
	drift.set_physics_process(false)
	reality_drift.set_physics_process(false)
	if not fantasy.expire_pocket(back_pocket_id):
		push_error("US-004 T004: Fantasy pocket expire failed")
		get_tree().quit(1)
		return
	drift.set_physics_process(false)
	reality_drift.set_physics_process(false)
	await get_tree().process_frame
	drift.set_physics_process(false)
	reality_drift.set_physics_process(false)
	if drift.is_fantasy_drift_eligible(west_cell):
		push_error("US-004 T004: expired Fantasy pocket must drop Fantasy eligibility")
		get_tree().quit(1)
		return
	if not reality_drift.is_reality_drift_eligible(west_cell):
		push_error("US-004 T004: after Fantasy pocket expire, Reality claim must be Reality-drift eligible")
		get_tree().quit(1)
		return
	west_tile = _outside_at(west_cell)
	if west_tile == null or west_tile.element_presentation == OutsideTile.ElementPresentation.FANTASY:
		push_error("US-025 T005: Reality-claimed cell must not stay Fantasy until Reality drift")
		get_tree().quit(1)
		return
	if west_tile.element_presentation != OutsideTile.ElementPresentation.NEUTRAL and west_tile.element_presentation != OutsideTile.ElementPresentation.REALITY:
		push_error("US-025 T005: after Fantasy loss under Reality claim expected Neutral or Reality, got %s" % west_tile.element_presentation)
		get_tree().quit(1)
		return
	if int(west_tile.ground_kind) != west_kind or int(west_tile.variety) != west_variety:
		push_error("US-025 T005: Reality-claimed strip must not change kind or variety")
		get_tree().quit(1)
		return
	if not _snapshot_matches(level, west_cell, west_kind, west_variety, int(west_tile.element_presentation)):
		push_error("US-025 T005: snapshot must match stripped presentation")
		get_tree().quit(1)
		return

	var reality_pocket_id: int = reality.spawn_pocket(home_cell, Vector2i(2, 2), 8.0)
	if reality_pocket_id < 0:
		push_error("US-004 T004: Reality pocket spawn failed")
		get_tree().quit(1)
		return
	if drift.is_fantasy_drift_eligible(home_cell):
		push_error("US-004 T004: Reality pocket must block Fantasy drift")
		get_tree().quit(1)
		return
	if ZoneDriftClaim.for_cell(get_tree(), home_cell) != ZoneDriftClaim.CLAIM_REALITY:
		push_error("US-004 T004: shared claim winner must be Reality under a Reality pocket")
		get_tree().quit(1)
		return
	if not reality.expire_pocket(reality_pocket_id):
		push_error("US-004 T004: Reality pocket expire failed")
		get_tree().quit(1)
		return

	PlayerManager.reality_level = 8
	DmManager.fantasy_level = 8
	reality.on_level_changed(8)
	fantasy.on_level_changed(8)
	await get_tree().process_frame
	if Zone.homes_occupy_same_cell(reality.home_rect, fantasy.home_rect):
		push_error("US-025 T001: Reality and Fantasy homes must not overlap after equal bump")
		get_tree().quit(1)
		return
	if reality.home_rect.has_point(home_cell) and fantasy.home_rect.has_point(home_cell):
		push_error("US-025 T001: a cell must not sit in both homes")
		get_tree().quit(1)
		return
	DmManager.fantasy_level = 12
	fantasy.on_level_changed(12)
	await get_tree().process_frame
	if Zone.homes_occupy_same_cell(reality.home_rect, fantasy.home_rect):
		push_error("US-025 T002: homes must stay disjoint after higher Fantasy Level")
		get_tree().quit(1)
		return
	if reality_drift.is_reality_drift_eligible(home_cell) and drift.is_fantasy_drift_eligible(home_cell):
		push_error("US-025 T002: a cell must not be drift-eligible for both zones")
		get_tree().quit(1)
		return

	PlayerManager.reality_level = 0
	DmManager.fantasy_level = 0
	print("US-004 Fantasy tile drift test passed")
	get_tree().quit(0)

func _first_outside_in_home(fantasy: FantasyZone, dungeon: Rect2i) -> Vector2i:
	var rect: Rect2i = fantasy.home_rect
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var cell := Vector2i(x, y)
			if dungeon.has_point(cell):
				continue
			if _outside_at(cell) != null:
				return cell
	return Vector2i(-999, -999)

func _outside_at(cell: Vector2i) -> OutsideTile:
	for node in get_tree().get_nodes_in_group("outside_tiles"):
		if node is OutsideTile and DungeonGrid.from_world((node as OutsideTile).position) == cell:
			return node as OutsideTile
	return null

func _count_fantasy() -> int:
	var n := 0
	for node in get_tree().get_nodes_in_group("outside_tiles"):
		if node is OutsideTile and (node as OutsideTile).element_presentation == OutsideTile.ElementPresentation.FANTASY:
			n += 1
	return n

func _count_eligible_not_fantasy(drift: FantasyTileDrift) -> int:
	var n := 0
	for node in get_tree().get_nodes_in_group("outside_tiles"):
		if not (node is OutsideTile):
			continue
		var tile: OutsideTile = node
		if tile.element_presentation == OutsideTile.ElementPresentation.FANTASY:
			continue
		var cell: Vector2i = DungeonGrid.from_world(tile.position)
		if drift.is_fantasy_drift_eligible(cell):
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
