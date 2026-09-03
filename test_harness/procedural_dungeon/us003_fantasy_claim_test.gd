extends Node

# US-003 T010 independent headless test. Two-window play pass is QA's.

func _ready() -> void:
	Zone.debug_claim_overlays = true
	DmManager.fantasy_level = 0
	PlayerManager.reality_level = 0
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

	var reality: RealityZone = load("res://zones/reality_zone.tscn").instantiate()
	reality.name = "HostReality"
	reality.add_to_group("RealityZone")
	add_child(reality)
	var fantasy: FantasyZone = load("res://zones/fantasy_zone.tscn").instantiate()
	fantasy.name = "HostFantasy"
	add_child(fantasy)
	await get_tree().process_frame
	await get_tree().physics_frame

	if not _check_home(fantasy, level, interior, dungeon):
		return
	if not await _check_pockets(fantasy, interior):
		return
	if not await _check_occupancy(fantasy, interior):
		return
	if not await _check_buildings(reality, fantasy, level):
		return
	if not await _check_skeletons(reality, fantasy, dungeon):
		return
	if not await _check_snapshot(fantasy, interior):
		return

	DmManager.fantasy_level = 0
	PlayerManager.reality_level = 0
	print("US-003 T010 independent test passed")
	print("US-003 T010 two-window play pass not run (QA owns it)")
	get_tree().quit(0)

func _fail(msg: String) -> bool:
	push_error("US-003 T010: " + msg)
	get_tree().quit(1)
	return false

func _fail_t011(msg: String) -> bool:
	push_error("US-003 T011: " + msg)
	get_tree().quit(1)
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

func _west_unclaimed(fantasy: FantasyZone, interior: Rect2i) -> Vector2i:
	var cell := Vector2i(interior.position.x + 1, interior.position.y + 1)
	if fantasy.is_claimed_cell(cell):
		cell = Vector2i(interior.position.x, interior.position.y)
	return cell

func _make_body() -> CharacterBody2D:
	var body := CharacterBody2D.new()
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	shape_node.shape = shape
	body.add_child(shape_node)
	body.collision_layer = 1
	body.collision_mask = 16
	return body

func _check_home(fantasy: FantasyZone, level: Node, interior: Rect2i, dungeon: Rect2i) -> bool:
	if not fantasy.home_rect.intersects(dungeon):
		return _fail("home must cover the east dungeon AABB")
	if fantasy.home_rect.end.x != interior.end.x:
		return _fail("home must east-anchor")
	if not _rect_inside_interior(fantasy.home_rect, level.map_bounds):
		return _fail("home covers non-interior cells")
	if not fantasy._resolve_collision_shape():
		return _fail("missing CollisionShape2D")
	if fantasy.collision_shape_2d.shape is CircleShape2D:
		return _fail("claim must ignore leftover circle")
	if not (fantasy.collision_shape_2d.shape is RectangleShape2D):
		return _fail("home collision must be a rectangle")
	var shape: RectangleShape2D = fantasy.collision_shape_2d.shape
	var expected := Vector2(fantasy.home_rect.size) * DungeonGrid.CELL_PX
	if shape.size != expected:
		return _fail("rect collision size %s expected %s" % [shape.size, expected])
	var overlay: Node2D = fantasy.get_node_or_null("HomeOverlay")
	if overlay == null:
		return _fail("HomeOverlay missing")
	var expected_cells: int = fantasy.home_rect.size.x * fantasy.home_rect.size.y
	if overlay.get_child_count() != expected_cells:
		return _fail("home overlay cells %d expected %d" % [overlay.get_child_count(), expected_cells])
	var sprite: Sprite2D = overlay.get_child(0) as Sprite2D
	if sprite == null or sprite.texture == null:
		return _fail("home overlay sprite missing texture")
	if str(sprite.texture.resource_path).find("fantasy_home_overlay.png") == -1:
		return _fail("home overlay must use fantasy_home_overlay.png")
	var west: Vector2i = interior.position
	if fantasy.is_claimed_cell(west) and not fantasy.home_rect.has_point(west):
		return _fail("west interior cell must not be home at level 0")
	if fantasy.overlay_kind_for_cell(fantasy.home_rect.position) != "home":
		return _fail("home-only cell must use home overlay")
	var start_rect: Rect2i = fantasy.home_rect
	DmManager.fantasy_level = 2
	fantasy.on_level_changed(2)
	if fantasy.home_rect == start_rect:
		return _fail("Fantasy Level should grow the home rect")
	if fantasy.home_rect.end.x != interior.end.x:
		return _fail("grown home must stay east-anchored")
	if not _rect_inside_interior(fantasy.home_rect, level.map_bounds):
		return _fail("grown home left interior")
	if fantasy.collision_shape_2d.shape is CircleShape2D:
		return _fail("growth must not restore circle collision")
	DmManager.fantasy_level = 10000
	fantasy.on_level_changed(10000)
	if fantasy.home_rect != interior:
		return _fail("huge growth should clip to interior, got %s" % fantasy.home_rect)
	DmManager.fantasy_level = 0
	fantasy.on_level_changed(0)
	if fantasy.home_rect.end.x != interior.end.x:
		return _fail("reset to level 0 should restore east anchor")
	return true

func _check_pockets(fantasy: FantasyZone, interior: Rect2i) -> bool:
	var degenerate: int = fantasy.spawn_pocket(Vector2i(4, 4), Vector2i(0, 3), 8.0)
	if degenerate != -1:
		return _fail("zero-size pocket must be rejected")
	var overflow_id: int = fantasy.spawn_pocket(Vector2i(-4, -2), Vector2i(6, 4), 8.0)
	if overflow_id < 0:
		return _fail("overflow pocket should clip, not reject")
	var overflow: Dictionary = fantasy.get_pocket(overflow_id)
	var overflow_rect: Rect2i = overflow["rect"]
	if overflow_rect.position.x < 0 or overflow_rect.position.y < 0:
		return _fail("clipped pocket left interior %s" % overflow_rect)
	if overflow_rect.end.x > interior.end.x or overflow_rect.end.y > interior.end.y:
		return _fail("clipped pocket overflowed interior %s" % overflow_rect)
	var cell: Vector2i = _west_unclaimed(fantasy, interior)
	var pocket_a: int = fantasy.spawn_pocket(cell, Vector2i(2, 2), 8.0)
	if pocket_a < 0:
		return _fail("pocket spawn failed")
	if not fantasy.is_claimed_cell(cell):
		return _fail("pocket cell must be Fantasy-claimed")
	if fantasy.overlay_kind_for_cell(cell) != "pocket":
		return _fail("pocket cell must use pocket overlay")
	var pocket_overlay: Node2D = fantasy.get_node_or_null("PocketOverlay")
	if pocket_overlay == null or pocket_overlay.get_child_count() <= 0:
		return _fail("PocketOverlay missing sprites")
	var pocket_sprite: Sprite2D = pocket_overlay.get_child(0) as Sprite2D
	if pocket_sprite == null or str(pocket_sprite.texture.resource_path).find("fantasy_pocket_overlay.png") == -1:
		return _fail("pocket overlay must use fantasy_pocket_overlay.png")
	var pocket_b: int = fantasy.spawn_pocket(cell, Vector2i(2, 2), 8.0)
	if fantasy.winning_pocket_id(cell) != pocket_b:
		return _fail("newer pocket must win overlap")
	if not fantasy.expire_pocket(pocket_b):
		return _fail("expire newer pocket failed")
	if fantasy.winning_pocket_id(cell) != pocket_a:
		return _fail("older pocket should remain after newer expires")
	fantasy.expire_pocket(pocket_a)
	fantasy.expire_pocket(overflow_id)
	if fantasy.is_claimed_cell(cell):
		return _fail("expired pocket must restore unclaimed ground")
	if not fantasy.is_claimed_cell(fantasy.home_rect.position):
		return _fail("home claim must survive pocket expire")
	return true

func _check_occupancy(fantasy: FantasyZone, interior: Rect2i) -> bool:
	if fantasy.get_node_or_null("Exclusion") != null:
		return _fail_t011("Fantasy Exclusion wall must not exist")
	var home_world: Vector2 = DungeonGrid.to_world_center(fantasy.home_rect.position)
	var outside_cell: Vector2i = _west_unclaimed(fantasy, interior)
	var outside_world: Vector2 = DungeonGrid.to_world_center(outside_cell)
	var paper := _make_body()
	paper.add_to_group("players")
	add_child(paper)
	paper.global_position = outside_world
	await get_tree().physics_frame
	if paper.test_move(paper.transform, home_world - paper.global_position):
		return _fail_t011("Paper Pusher must not be blocked by a Fantasy wall")
	var dm := _make_body()
	dm.add_to_group("dm")
	add_child(dm)
	dm.global_position = outside_world
	await get_tree().physics_frame
	if dm.test_move(dm.transform, home_world - dm.global_position):
		return _fail("DM must walk into Fantasy-claimed space")
	dm.global_position = home_world
	await get_tree().physics_frame
	if not fantasy.is_claimed_world(dm.global_position):
		return _fail("DM must remain inside Fantasy")
	paper.global_position = home_world
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_instance_valid(paper):
		return _fail_t011("Paper Pusher must remain alive inside Fantasy")
	if not fantasy.is_claimed_world(paper.global_position):
		return _fail_t011("Paper Pusher inside Fantasy must not be pushed out")
	if not paper.global_position.is_equal_approx(home_world):
		return _fail_t011("Paper Pusher must stay at the Fantasy home cell")
	paper.global_position = outside_world
	await get_tree().physics_frame
	if fantasy.is_claimed_world(paper.global_position):
		return _fail_t011("Paper Pusher must be able to leave Fantasy")
	return true

func _check_buildings(reality: RealityZone, fantasy: FantasyZone, _level: Node) -> bool:
	var size := Vector2(128, 128)
	var home_cell: Vector2i = reality.home_rect.position
	var home_pos: Vector2 = DungeonGrid.to_world_center(home_cell)
	if not BuildingManager.is_area_clear(home_pos, size):
		return _fail("Reality home outside Fantasy must still accept")
	var fantasy_pos: Vector2 = DungeonGrid.to_world_center(fantasy.home_rect.position)
	if BuildingManager.is_area_clear(fantasy_pos, size):
		return _fail("footprint intersecting Fantasy home must reject")
	var pocket_id: int = fantasy.spawn_pocket(home_cell, Vector2i(2, 2), 8.0)
	if pocket_id < 0:
		return _fail("Fantasy pocket over Reality home failed")
	if BuildingManager.is_area_clear(home_pos, size):
		return _fail("footprint intersecting a Fantasy pocket must reject")
	if not fantasy.expire_pocket(pocket_id):
		return _fail("pocket expire failed")
	if not BuildingManager.is_area_clear(home_pos, size):
		return _fail("Reality home must accept again after Fantasy pocket expires")
	var factory: Node2D = load("res://buildings/buildables/paper_factory.tscn").instantiate() as Node2D
	add_child(factory)
	factory.global_position = home_pos
	await get_tree().process_frame
	var cover_id: int = fantasy.spawn_pocket(home_cell, Vector2i(2, 2), 8.0)
	if cover_id < 0:
		return _fail("Fantasy pocket over factory failed")
	await get_tree().process_frame
	if not is_instance_valid(factory):
		return _fail("existing building must not be auto-destroyed")
	fantasy.expire_pocket(cover_id)
	return true

func _check_skeletons(reality: RealityZone, fantasy: FantasyZone, dungeon: Rect2i) -> bool:
	var dungeon_cell := Vector2i(dungeon.position.x + 1, dungeon.position.y + 1)
	var dungeon_world: Vector2 = DungeonGrid.to_world_center(dungeon_cell)
	if not fantasy.is_claimed_cell(dungeon_cell):
		return _fail("dungeon cell should start in Fantasy home")
	if reality.is_claimed_cell(dungeon_cell):
		return _fail("dungeon cell must not start Reality-claimed")
	if RealityClaim.should_despawn_skeleton(get_tree(), dungeon_world):
		return _fail("Fantasy-only cell must allow skeletons")
	var skel: Skeleton = load("res://monsters/skeleton/skeleton.tscn").instantiate()
	add_child(skel)
	skel.global_position = dungeon_world
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_instance_valid(skel) or skel._dying:
		return _fail("skeleton in Fantasy home must live")
	var goblin: Node2D = load("res://monsters/goblin.tscn").instantiate() as Node2D
	add_child(goblin)
	goblin.global_position = dungeon_world
	await get_tree().physics_frame
	if not is_instance_valid(goblin) or goblin.get("_dying") == true:
		return _fail("goblin must be unchanged")
	var reality_home: Vector2 = DungeonGrid.to_world_center(reality.home_rect.position)
	var fantasy_pocket: int = fantasy.spawn_pocket(reality.home_rect.position, Vector2i(2, 2), 8.0)
	if fantasy_pocket < 0:
		return _fail("Fantasy pocket over Reality home failed")
	if RealityClaim.should_despawn_skeleton(get_tree(), reality_home):
		return _fail("Fantasy pocket must override Reality home for skeletons")
	var reality_pocket: int = reality.spawn_pocket(dungeon_cell, Vector2i(2, 2), 8.0)
	if reality_pocket < 0:
		return _fail("Reality pocket over dungeon failed")
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_instance_valid(skel) or not skel._dying:
		return _fail("Reality pocket must still ban the dungeon skeleton")
	fantasy.expire_pocket(fantasy_pocket)
	reality.expire_pocket(reality_pocket)
	PlayerManager.reality_level = 10000
	DmManager.fantasy_level = 10000
	reality.on_level_changed(10000)
	fantasy.on_level_changed(10000)
	var probe_cell := Vector2i(8, 5)
	if reality.is_claimed_cell(probe_cell) and fantasy.is_claimed_cell(probe_cell):
		return _fail("US-025: grown homes must not overlap")
	var grown_reality: Vector2 = DungeonGrid.to_world_center(reality.home_rect.position)
	if not RealityClaim.should_despawn_skeleton(get_tree(), grown_reality):
		return _fail("Reality-claimed home must still ban skeletons")
	var grown_fantasy: Vector2 = DungeonGrid.to_world_center(fantasy.home_rect.position)
	if RealityClaim.should_despawn_skeleton(get_tree(), grown_fantasy):
		return _fail("Fantasy-only home must still allow skeletons")
	PlayerManager.reality_level = 0
	DmManager.fantasy_level = 0
	reality.on_level_changed(0)
	fantasy.on_level_changed(0)
	return true

func _check_snapshot(fantasy: FantasyZone, interior: Rect2i) -> bool:
	var peer: FantasyZone = load("res://zones/fantasy_zone.tscn").instantiate()
	peer.name = "PeerFantasy"
	add_child(peer)
	await get_tree().process_frame
	var cell: Vector2i = _west_unclaimed(fantasy, interior)
	var pocket_id: int = fantasy.spawn_pocket(cell, Vector2i(2, 2), 8.0)
	if pocket_id < 0:
		return _fail("snapshot pocket spawn failed")
	var payload: Dictionary = fantasy.build_claim_sync_payload()
	if payload.has("radius") or payload.has("base_radius"):
		return _fail("claim snapshot must not replicate circle radius")
	var packed: Array = payload.get("pockets", [])
	if packed.is_empty() or float(packed[0].get("remaining", 0.0)) <= 0.0:
		return _fail("snapshot missing live pocket remaining duration")
	if int(payload.get("home_w", 0)) <= 0:
		return _fail("snapshot missing home rect")
	peer.apply_claim_sync_payload(payload)
	await get_tree().process_frame
	if peer.home_rect != fantasy.home_rect:
		return _fail("peer home_rect %s != host %s" % [peer.home_rect, fantasy.home_rect])
	if not peer.is_claimed_cell(cell) or peer.overlay_kind_for_cell(cell) != "pocket":
		return _fail("peer must apply live pocket claim and overlay")
	if peer.winning_pocket_id(cell) != pocket_id:
		return _fail("peer pocket id %s != host %s" % [peer.winning_pocket_id(cell), pocket_id])
	fantasy.expire_pocket(pocket_id)
	peer.apply_claim_sync_payload(fantasy.build_claim_sync_payload())
	await get_tree().process_frame
	if peer.is_claimed_cell(cell):
		return _fail("peer pocket claim survived expire snapshot")
	if not peer.is_claimed_cell(fantasy.home_rect.position):
		return _fail("peer home must survive expire snapshot")
	return true
