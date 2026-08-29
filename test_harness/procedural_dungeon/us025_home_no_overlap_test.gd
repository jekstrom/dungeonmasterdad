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
	var fantasy_drift: FantasyTileDrift = level.get_node_or_null("FantasyTileDrift")
	if reality_drift == null or fantasy_drift == null:
		push_error("US-025 T007: tile drift nodes missing")
		get_tree().quit(1)
		return
	reality_drift.set_physics_process(false)
	fantasy_drift.set_physics_process(false)
	reality_drift.clear_schedules()
	fantasy_drift.clear_schedules()

	var reality: RealityZone = load("res://zones/reality_zone.tscn").instantiate()
	var fantasy: FantasyZone = load("res://zones/fantasy_zone.tscn").instantiate()
	add_child(reality)
	reality_drift.set_physics_process(false)
	fantasy_drift.set_physics_process(false)
	add_child(fantasy)
	reality_drift.set_physics_process(false)
	fantasy_drift.set_physics_process(false)
	await get_tree().process_frame
	reality_drift.set_physics_process(false)
	fantasy_drift.set_physics_process(false)

	if Zone.homes_occupy_same_cell(reality.home_rect, fantasy.home_rect):
		push_error("US-025 T001: level-0 homes must not overlap")
		get_tree().quit(1)
		return

	var bounds: MapBounds = level.get_map_bounds()

	# Grow until unconstrained rects would overlap, then assert exclusive homes.
	PlayerManager.reality_level = 5
	DmManager.fantasy_level = 3
	reality.on_level_changed(5)
	fantasy.on_level_changed(3)
	reality_drift.set_physics_process(false)
	fantasy_drift.set_physics_process(false)
	await get_tree().process_frame
	reality_drift.set_physics_process(false)
	fantasy_drift.set_physics_process(false)
	var r_prop: Rect2i = reality.proposed_home_rect(bounds, interior)
	var f_prop: Rect2i = fantasy.proposed_home_rect(bounds, interior)
	if not Zone.homes_occupy_same_cell(r_prop, f_prop):
		push_error("US-025 T007: fixture must grow until proposed homes overlap, got %s vs %s" % [r_prop, f_prop])
		get_tree().quit(1)
		return
	if Zone.homes_occupy_same_cell(reality.home_rect, fantasy.home_rect):
		push_error("US-025 T001: resolved homes must be disjoint, got %s vs %s" % [reality.home_rect, fantasy.home_rect])
		get_tree().quit(1)
		return
	if reality.home_rect.position.x != interior.position.x:
		push_error("US-025 T002: Reality must keep the west anchor, got %s" % reality.home_rect)
		get_tree().quit(1)
		return
	if fantasy.home_rect.end.x != interior.end.x and fantasy.home_rect.size.x > 0:
		push_error("US-025 T002: Fantasy must keep the east anchor, got %s" % fantasy.home_rect)
		get_tree().quit(1)
		return

	var contested: Rect2i = r_prop.intersection(f_prop)
	for y in range(contested.position.y, contested.end.y):
		for x in range(contested.position.x, contested.end.x):
			var cell := Vector2i(x, y)
			if not reality.home_rect.has_point(cell):
				push_error("US-025 T002: higher Reality must keep contested cell %s" % cell)
				get_tree().quit(1)
				return
			if fantasy.home_rect.has_point(cell):
				push_error("US-025 T002: weaker Fantasy must not keep contested cell %s" % cell)
				get_tree().quit(1)
				return
			if not reality.is_claimed_cell(cell):
				push_error("US-025 T002: occupancy must follow the shrunk Fantasy / kept Reality rect at %s" % cell)
				get_tree().quit(1)
				return
			if dungeon.has_point(cell):
				continue
			if not reality_drift.is_reality_drift_eligible(cell):
				push_error("US-025 T002: drift must follow Reality claim on contested cell %s" % cell)
				get_tree().quit(1)
				return
			if fantasy_drift.is_fantasy_drift_eligible(cell):
				push_error("US-025 T002: Fantasy drift must not stay eligible on lost contested cell %s" % cell)
				get_tree().quit(1)
				return
	if fantasy.home_rect.size.x > 0 and fantasy.home_rect.position.x < reality.home_rect.end.x:
		push_error("US-025 T002: Fantasy west face must shrink to the Reality frontier")
		get_tree().quit(1)
		return

	# Higher Fantasy: Reality shrinks from the east.
	PlayerManager.reality_level = 3
	DmManager.fantasy_level = 5
	reality.on_level_changed(3)
	fantasy.on_level_changed(5)
	reality_drift.set_physics_process(false)
	fantasy_drift.set_physics_process(false)
	await get_tree().process_frame
	reality_drift.set_physics_process(false)
	fantasy_drift.set_physics_process(false)
	r_prop = reality.proposed_home_rect(bounds, interior)
	f_prop = fantasy.proposed_home_rect(bounds, interior)
	if Zone.homes_occupy_same_cell(reality.home_rect, fantasy.home_rect):
		push_error("US-025 T002: homes must be disjoint when Fantasy is stronger")
		get_tree().quit(1)
		return
	if reality.home_rect.position.x != interior.position.x:
		push_error("US-025 T002: weaker Reality must still west-anchor, got %s" % reality.home_rect)
		get_tree().quit(1)
		return
	contested = r_prop.intersection(f_prop)
	for y in range(contested.position.y, contested.end.y):
		for x in range(contested.position.x, contested.end.x):
			var cell := Vector2i(x, y)
			if not fantasy.home_rect.has_point(cell):
				push_error("US-025 T002: higher Fantasy must keep contested cell %s" % cell)
				get_tree().quit(1)
				return
			if reality.home_rect.has_point(cell):
				push_error("US-025 T002: weaker Reality must not keep contested cell %s" % cell)
				get_tree().quit(1)
				return
	if reality.home_rect.size.x > 0 and reality.home_rect.end.x > fantasy.home_rect.position.x:
		push_error("US-025 T002: Reality east face must shrink to the Fantasy frontier")
		get_tree().quit(1)
		return

	# Equal value: stable frontier, odd-width leftover unclaimed, no dual-claim.
	PlayerManager.reality_level = 8
	DmManager.fantasy_level = 8
	reality.on_level_changed(8)
	fantasy.on_level_changed(8)
	reality_drift.set_physics_process(false)
	fantasy_drift.set_physics_process(false)
	await get_tree().process_frame
	reality_drift.set_physics_process(false)
	fantasy_drift.set_physics_process(false)
	if Zone.homes_occupy_same_cell(reality.home_rect, fantasy.home_rect):
		push_error("US-025 T003: equal-value homes must not dual-cover a cell")
		get_tree().quit(1)
		return
	r_prop = reality.proposed_home_rect(bounds, interior)
	f_prop = fantasy.proposed_home_rect(bounds, interior)
	contested = r_prop.intersection(f_prop)
	var leftover := 0
	for y in range(contested.position.y, contested.end.y):
		for x in range(contested.position.x, contested.end.x):
			var cell := Vector2i(x, y)
			var in_r := reality.home_rect.has_point(cell)
			var in_f := fantasy.home_rect.has_point(cell)
			if in_r and in_f:
				push_error("US-025 T003: dual-claim forbidden at %s" % cell)
				get_tree().quit(1)
				return
			if not in_r and not in_f:
				leftover += 1
	var band: int = contested.size.x
	var max_leftover: int = contested.size.y if (band % 2) == 1 else 0
	if leftover > max_leftover:
		push_error("US-025 T003: too many unclaimed leftover cells %d band %d" % [leftover, band])
		get_tree().quit(1)
		return
	if reality.home_rect.size.x > 0 and fantasy.home_rect.size.x > 0:
		if reality.home_rect.end.x > fantasy.home_rect.position.x:
			push_error("US-025 T003: equal frontier must not let Reality grow into Fantasy")
			get_tree().quit(1)
			return
	var equal_reality: Rect2i = reality.home_rect
	var equal_fantasy: Rect2i = fantasy.home_rect
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	if reality.home_rect != equal_reality or fantasy.home_rect != equal_fantasy:
		push_error("US-025 T003: equal frontier must hold across physics frames")
		get_tree().quit(1)
		return

	# T004: pocket overrides without moving homes.
	var reality_cell: Vector2i = _first_cell(reality.home_rect, dungeon)
	if reality_cell.x < -900:
		push_error("US-025 T004: Reality home has no outside cell")
		get_tree().quit(1)
		return
	var homes_before_r: Rect2i = reality.home_rect
	var homes_before_f: Rect2i = fantasy.home_rect
	var pocket_id: int = fantasy.spawn_pocket(reality_cell, Vector2i(2, 2), 8.0)
	if pocket_id < 0:
		push_error("US-025 T004: Fantasy pocket over Reality home failed")
		get_tree().quit(1)
		return
	if reality.home_rect != homes_before_r or fantasy.home_rect != homes_before_f:
		push_error("US-025 T004: pocket create must not change home rects")
		get_tree().quit(1)
		return
	if ZoneDriftClaim.for_cell(get_tree(), reality_cell) != ZoneDriftClaim.CLAIM_FANTASY:
		push_error("US-025 T004: live Fantasy pocket must override Reality home")
		get_tree().quit(1)
		return
	if not fantasy.is_claimed_cell(reality_cell):
		push_error("US-025 T004: occupancy must follow the live pocket")
		get_tree().quit(1)
		return
	if not fantasy.expire_pocket(pocket_id):
		push_error("US-025 T004: pocket expire failed")
		get_tree().quit(1)
		return
	if reality.home_rect != homes_before_r or fantasy.home_rect != homes_before_f:
		push_error("US-025 T004: pocket expire must not change home rects")
		get_tree().quit(1)
		return
	if Zone.homes_occupy_same_cell(reality.home_rect, fantasy.home_rect):
		push_error("US-025 T004: homes must stay disjoint after pocket expire")
		get_tree().quit(1)
		return
	if ZoneDriftClaim.for_cell(get_tree(), reality_cell) != ZoneDriftClaim.CLAIM_REALITY:
		push_error("US-025 T004: expired pocket must fall back to the Reality home")
		get_tree().quit(1)
		return

	# T005: stale art strips immediately; Neutral→claimed stays staggered.
	var leak_cell: Vector2i = _unclaimed_outside(interior, dungeon, reality, fantasy)
	var leak_tile: OutsideTile = _outside_at(leak_cell)
	if leak_tile == null:
		push_error("US-025 T005: unclaimed outside tile missing")
		get_tree().quit(1)
		return
	var leak_kind: int = int(leak_tile.ground_kind)
	var leak_variety: int = int(leak_tile.variety)
	leak_tile.element_presentation = OutsideTile.ElementPresentation.FANTASY
	SignalBus.fantasy_claim_changed.emit()
	fantasy_drift.set_physics_process(false)
	reality_drift.set_physics_process(false)
	await get_tree().process_frame
	fantasy_drift.set_physics_process(false)
	reality_drift.set_physics_process(false)
	leak_tile = _outside_at(leak_cell)
	if leak_tile == null or leak_tile.element_presentation == OutsideTile.ElementPresentation.FANTASY:
		push_error("US-025 T005: Fantasy art must not linger on an unclaimed cell")
		get_tree().quit(1)
		return
	if leak_tile.element_presentation != OutsideTile.ElementPresentation.NEUTRAL:
		push_error("US-025 T005: unclaimed cell must snap Neutral, got %s" % leak_tile.element_presentation)
		get_tree().quit(1)
		return
	if int(leak_tile.ground_kind) != leak_kind or int(leak_tile.variety) != leak_variety:
		push_error("US-025 T005: strip must not change kind or variety")
		get_tree().quit(1)
		return
	if not _snapshot_matches(level, leak_cell, leak_kind, leak_variety, int(OutsideTile.ElementPresentation.NEUTRAL)):
		push_error("US-025 T006: snapshot must show Neutral after Fantasy strip")
		get_tree().quit(1)
		return

	var reality_tile: OutsideTile = _outside_at(reality_cell)
	if reality_tile == null:
		push_error("US-025 T005: Reality home outside tile missing")
		get_tree().quit(1)
		return
	var r_kind: int = int(reality_tile.ground_kind)
	var r_variety: int = int(reality_tile.variety)
	reality_tile.element_presentation = OutsideTile.ElementPresentation.FANTASY
	SignalBus.reality_claim_changed.emit()
	fantasy_drift.set_physics_process(false)
	reality_drift.set_physics_process(false)
	await get_tree().process_frame
	fantasy_drift.set_physics_process(false)
	reality_drift.set_physics_process(false)
	reality_tile = _outside_at(reality_cell)
	if reality_tile == null or reality_tile.element_presentation == OutsideTile.ElementPresentation.FANTASY:
		push_error("US-025 T005: Reality-claimed cell must not stay Fantasy until Reality drift")
		get_tree().quit(1)
		return
	if reality_tile.element_presentation == OutsideTile.ElementPresentation.REALITY:
		push_error("US-025 T005: must not instantly convert Neutral/Fantasy into Reality art")
		get_tree().quit(1)
		return
	if int(reality_tile.ground_kind) != r_kind or int(reality_tile.variety) != r_variety:
		push_error("US-025 T005: Reality-home strip must not change kind or variety")
		get_tree().quit(1)
		return

	leak_tile = _outside_at(leak_cell)
	leak_tile.element_presentation = OutsideTile.ElementPresentation.REALITY
	SignalBus.reality_claim_changed.emit()
	fantasy_drift.set_physics_process(false)
	reality_drift.set_physics_process(false)
	await get_tree().process_frame
	if _outside_at(leak_cell).element_presentation == OutsideTile.ElementPresentation.REALITY:
		push_error("US-025 T005: Reality art must not linger without Reality claim")
		get_tree().quit(1)
		return

	# T006: shrunk homes are in the existing claim snapshot.
	var reality_payload: Dictionary = reality.build_claim_sync_payload()
	if int(reality_payload.get("home_x", 0)) != reality.home_rect.position.x or int(reality_payload.get("home_w", 0)) != reality.home_rect.size.x:
		push_error("US-025 T006: Reality claim snapshot must reuse the shrunk home rect")
		get_tree().quit(1)
		return
	var fantasy_payload: Dictionary = fantasy.build_claim_sync_payload()
	if int(fantasy_payload.get("home_x", 0)) != fantasy.home_rect.position.x or int(fantasy_payload.get("home_w", 0)) != fantasy.home_rect.size.x:
		push_error("US-025 T006: Fantasy claim snapshot must reuse the shrunk home rect")
		get_tree().quit(1)
		return

	# T007: huge home is clip-only; no game-over / match-end.
	PlayerManager.reality_level = 10000
	DmManager.fantasy_level = 0
	reality.on_level_changed(10000)
	fantasy.on_level_changed(0)
	await get_tree().process_frame
	if not _rect_inside_interior(reality.home_rect, bounds) and reality.home_rect.size.x > 0:
		push_error("US-025 T007: large Reality home must stay clipped to interior")
		get_tree().quit(1)
		return
	if Zone.homes_occupy_same_cell(reality.home_rect, fantasy.home_rect):
		push_error("US-025 T007: large Reality home must not overlap Fantasy")
		get_tree().quit(1)
		return

	PlayerManager.reality_level = 0
	DmManager.fantasy_level = 0
	print("US-025 home no-overlap test passed")
	get_tree().quit(0)

func _first_cell(rect: Rect2i, dungeon: Rect2i) -> Vector2i:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var cell := Vector2i(x, y)
			if dungeon.has_point(cell):
				continue
			if _outside_at(cell) != null:
				return cell
	return Vector2i(-999, -999)

func _unclaimed_outside(interior: Rect2i, dungeon: Rect2i, reality: RealityZone, fantasy: FantasyZone) -> Vector2i:
	for y in range(interior.position.y, interior.end.y):
		for x in range(interior.position.x, interior.end.x):
			var cell := Vector2i(x, y)
			if dungeon.has_point(cell):
				continue
			if reality.is_claimed_cell(cell) or fantasy.is_claimed_cell(cell):
				continue
			if _outside_at(cell) != null:
				return cell
	return Vector2i(interior.position.x, interior.end.y - 1)

func _outside_at(cell: Vector2i) -> OutsideTile:
	for node in get_tree().get_nodes_in_group("outside_tiles"):
		if node is OutsideTile and DungeonGrid.from_world((node as OutsideTile).position) == cell:
			return node as OutsideTile
	return null

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

func _rect_inside_interior(rect: Rect2i, bounds: MapBounds) -> bool:
	if rect.size.x <= 0 or rect.size.y <= 0:
		return false
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var cell := Vector2i(x, y)
			if not bounds.is_interior_cell(cell):
				return false
			if bounds.is_cliff_cell(cell):
				return false
	return true
