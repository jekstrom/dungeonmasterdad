extends Node

# US-001 T009 independent headless test. Two-window play pass is QA's.

func _ready() -> void:
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
	await get_tree().process_frame

	if not _check_home(reality, level, interior):
		return
	if not await _check_pockets(reality, interior):
		return
	if not await _check_occupancy(reality, interior):
		return
	if not await _check_buildings(reality, level, interior, dungeon):
		return
	if not await _check_skeletons(reality, dungeon):
		return
	if not await _check_snapshot(reality, interior):
		return

	PlayerManager.reality_level = 0
	print("US-001 T009 independent test passed")
	print("US-001 T009 two-window play pass not run (QA owns it)")
	get_tree().quit(0)

func _fail(msg: String) -> bool:
	push_error("US-001 T009: " + msg)
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

func _east_unclaimed(reality: RealityZone, interior: Rect2i) -> Vector2i:
	var cell := Vector2i(interior.end.x - 3, interior.position.y + 1)
	if reality.home_rect.has_point(cell):
		cell = Vector2i(interior.end.x - 1, interior.end.y - 1)
	return cell

func _check_home(reality: RealityZone, level: Node, interior: Rect2i) -> bool:
	if reality.home_rect.position.x != interior.position.x:
		return _fail("home must west-anchor")
	if not _rect_inside_interior(reality.home_rect, level.map_bounds):
		return _fail("home covers non-interior cells")
	if not reality._resolve_collision_shape():
		return _fail("missing CollisionShape2D")
	if reality.collision_shape_2d.shape is CircleShape2D:
		return _fail("claim must ignore leftover circle")
	if not (reality.collision_shape_2d.shape is RectangleShape2D):
		return _fail("home collision must be a rectangle")
	var shape: RectangleShape2D = reality.collision_shape_2d.shape
	var expected := Vector2(reality.home_rect.size) * DungeonGrid.CELL_PX
	if shape.size != expected:
		return _fail("rect collision size %s expected %s" % [shape.size, expected])

	var overlay: Node2D = reality.get_node_or_null("HomeOverlay")
	if overlay == null:
		return _fail("HomeOverlay missing")
	var expected_cells: int = reality.home_rect.size.x * reality.home_rect.size.y
	if overlay.get_child_count() != expected_cells:
		return _fail("home overlay cells %d expected %d" % [overlay.get_child_count(), expected_cells])
	var sprite: Sprite2D = overlay.get_child(0) as Sprite2D
	if sprite == null or sprite.texture == null:
		return _fail("home overlay sprite missing texture")
	if str(sprite.texture.resource_path).find("reality_home_overlay.png") == -1:
		return _fail("home overlay must use reality_home_overlay.png")

	var west: Vector2i = reality.home_rect.position
	var east := Vector2i(interior.end.x - 1, interior.position.y)
	if not reality.is_claimed_cell(west):
		return _fail("west home cell must be claimed")
	if not reality.contains_world_position(DungeonGrid.to_world_center(west)):
		return _fail("west cell world query must follow the rect")
	if reality.is_claimed_cell(east) and not reality.home_rect.has_point(east):
		return _fail("east interior cell must not be home at level 0")
	if reality.overlay_kind_for_cell(west) != "home":
		return _fail("home-only cell must use home overlay")

	var start_width: int = reality.home_rect.size.x
	PlayerManager.reality_level = 2
	reality.on_level_changed(2)
	if reality.home_rect.size.x != start_width + 2:
		return _fail("Reality Level should grow width by 2, got %s from %s" % [reality.home_rect.size.x, start_width])
	if not _rect_inside_interior(reality.home_rect, level.map_bounds):
		return _fail("grown home left interior")
	if reality.collision_shape_2d.shape is CircleShape2D:
		return _fail("growth must not restore circle collision")

	PlayerManager.reality_level = 10000
	reality.on_level_changed(10000)
	if reality.home_rect != interior:
		return _fail("huge growth should clip to interior, got %s" % reality.home_rect)

	PlayerManager.reality_level = 0
	reality.on_level_changed(0)
	if reality.home_rect.size.x != start_width:
		return _fail("reset to level 0 should restore start width")
	return true

func _check_pockets(reality: RealityZone, interior: Rect2i) -> bool:
	var degenerate: int = reality.spawn_pocket(Vector2i(4, 4), Vector2i(0, 3), 8.0)
	if degenerate != -1:
		return _fail("zero-size pocket must be rejected")

	var overflow_id: int = reality.spawn_pocket(Vector2i(-4, -2), Vector2i(6, 4), 8.0)
	if overflow_id < 0:
		return _fail("overflow pocket should clip, not reject")
	var overflow: Dictionary = reality.get_pocket(overflow_id)
	var overflow_rect: Rect2i = overflow["rect"]
	if overflow_rect.position.x < 0 or overflow_rect.position.y < 0:
		return _fail("clipped pocket left interior %s" % overflow_rect)
	if overflow_rect.end.x > interior.end.x or overflow_rect.end.y > interior.end.y:
		return _fail("clipped pocket overflowed interior %s" % overflow_rect)

	var cell: Vector2i = _east_unclaimed(reality, interior)
	var pocket_a: int = reality.spawn_pocket(cell, Vector2i(2, 2), 8.0)
	if pocket_a < 0:
		return _fail("pocket spawn failed")
	if not reality.is_claimed_cell(cell):
		return _fail("pocket cell must be Reality-claimed")
	if reality.overlay_kind_for_cell(cell) != "pocket":
		return _fail("pocket cell must use pocket overlay")
	var pocket_overlay: Node2D = reality.get_node_or_null("PocketOverlay")
	if pocket_overlay == null or pocket_overlay.get_child_count() <= 0:
		return _fail("PocketOverlay missing sprites")
	var pocket_sprite: Sprite2D = pocket_overlay.get_child(0) as Sprite2D
	if pocket_sprite == null or str(pocket_sprite.texture.resource_path).find("reality_pocket_overlay.png") == -1:
		return _fail("pocket overlay must use reality_pocket_overlay.png")

	var pocket_b: int = reality.spawn_pocket(cell, Vector2i(2, 2), 8.0)
	if reality.winning_pocket_id(cell) != pocket_b:
		return _fail("newer pocket must win overlap, got %s want %s" % [reality.winning_pocket_id(cell), pocket_b])
	if not reality.expire_pocket(pocket_b):
		return _fail("expire newer pocket failed")
	if reality.winning_pocket_id(cell) != pocket_a:
		return _fail("older pocket should remain after newer expires")

	reality.expire_pocket(pocket_a)
	reality.expire_pocket(overflow_id)
	if reality.is_claimed_cell(cell):
		return _fail("expired pocket must restore unclaimed ground")
	if reality.get_node("PocketOverlay").get_child_count() != 0:
		return _fail("PocketOverlay should be empty after expire")
	if not reality.is_claimed_cell(reality.home_rect.position):
		return _fail("home claim must survive pocket expire")

	var timed: int = reality.spawn_pocket(cell, Vector2i(1, 1), 0.05)
	if timed < 0:
		return _fail("short-duration pocket spawn failed")
	await get_tree().create_timer(0.2).timeout
	if reality.is_claimed_cell(cell):
		return _fail("timer expire did not restore claim")
	return true

func _check_occupancy(reality: RealityZone, interior: Rect2i) -> bool:
	var home_cell: Vector2i = reality.home_rect.position
	var home_world: Vector2 = DungeonGrid.to_world_center(home_cell)
	var pocket_cell: Vector2i = _east_unclaimed(reality, interior)
	if reality.is_claimed_cell(pocket_cell):
		return _fail("occupancy fixture cell must start unclaimed")
	if not reality.is_claimed_world(home_world):
		return _fail("Paper Pusher home cell must be claimed")

	var pocket_id: int = reality.spawn_pocket(pocket_cell, Vector2i(2, 2), 8.0)
	if pocket_id < 0:
		return _fail("occupancy pocket spawn failed")
	var pocket_world: Vector2 = DungeonGrid.to_world_center(pocket_cell)
	if not reality.is_claimed_world(pocket_world):
		return _fail("pocket cell must be occupied as Reality")
	if not reality.is_position_within_zone(pocket_world):
		return _fail("DM/PP occupancy query must include pockets")
	if reality.collision_shape_2d.shape is CircleShape2D:
		return _fail("occupancy must not use a circle")

	var walker := CharacterBody2D.new()
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	shape_node.shape = shape
	walker.add_child(shape_node)
	walker.collision_layer = 1
	walker.collision_mask = 1
	add_child(walker)
	walker.global_position = DungeonGrid.to_world_center(Vector2i(interior.end.x - 1, interior.end.y - 1))
	await get_tree().physics_frame
	if walker.test_move(walker.transform, home_world - walker.global_position):
		return _fail("Reality Area2D must not be a zone wall")
	walker.global_position = home_world
	await get_tree().physics_frame
	if not reality.is_claimed_world(walker.global_position):
		return _fail("walker inside home must occupy Reality")

	var wall := StaticBody2D.new()
	var wall_shape := CollisionShape2D.new()
	var wall_rect := RectangleShape2D.new()
	wall_rect.size = Vector2(64, 64)
	wall_shape.shape = wall_rect
	wall.add_child(wall_shape)
	wall.collision_layer = 1
	add_child(wall)
	wall.global_position = home_world + Vector2(80, 0)
	await get_tree().physics_frame
	if not walker.test_move(walker.transform, Vector2(80, 0)):
		return _fail("walls/buildings must still collide")

	walker.queue_free()
	wall.queue_free()
	await get_tree().physics_frame
	reality.expire_pocket(pocket_id)
	return true

func _check_buildings(reality: RealityZone, level: Node, interior: Rect2i, dungeon: Rect2i) -> bool:
	var occupied := Vector2i(dungeon.position)
	var dungeon_tile: Node2D = load("res://level/floor.tscn").instantiate() as Node2D
	dungeon_tile.position = DungeonGrid.to_world(occupied)
	dungeon_tile.add_to_group("generated_dungeon_tiles")
	add_child(dungeon_tile)
	await get_tree().process_frame

	var home_cell: Vector2i = reality.home_rect.position
	if not level.is_outside_build_cell(home_cell):
		return _fail("west home cell should be outside grass/dirt")
	if level.is_outside_build_cell(occupied):
		return _fail("dungeon cell must not be a build cell")

	var size := Vector2(128, 128)
	var home_pos: Vector2 = DungeonGrid.to_world_center(home_cell)
	if not BuildingManager.is_area_clear(home_pos, size):
		return _fail("full Reality outside footprint must accept")

	var outside_home: Vector2i = _east_unclaimed(reality, interior)
	var outside_pos: Vector2 = DungeonGrid.to_world_center(outside_home)
	if BuildingManager.is_area_clear(outside_pos, size):
		return _fail("footprint outside Reality must reject")
	var dungeon_pos: Vector2 = DungeonGrid.to_world_center(occupied)
	if BuildingManager.is_area_clear(dungeon_pos, size):
		return _fail("dungeon footprint must reject")

	var pocket_id: int = reality.spawn_pocket(outside_home, Vector2i(2, 2), 8.0)
	if pocket_id < 0:
		return _fail("pocket for building test failed")
	if not BuildingManager.is_area_clear(outside_pos, size):
		return _fail("pocket on outside tiles must accept")
	reality.expire_pocket(pocket_id)
	return true

func _check_skeletons(reality: RealityZone, dungeon: Rect2i) -> bool:
	var home_world: Vector2 = DungeonGrid.to_world_center(reality.home_rect.position)
	var dungeon_cell := Vector2i(dungeon.position.x + 1, dungeon.position.y + 1)
	var dungeon_world: Vector2 = DungeonGrid.to_world_center(dungeon_cell)
	if reality.is_claimed_cell(dungeon_cell):
		return _fail("dungeon fixture must start unclaimed")
	if not RealityClaim.should_reject_skeleton_spawn(get_tree(), RealityClaim.SKELETON_SCENE_PATH, home_world):
		return _fail("skeleton spawn on home must reject")
	if RealityClaim.should_reject_skeleton_spawn(get_tree(), "res://monsters/goblin.tscn", home_world):
		return _fail("goblin spawn must not use skeleton ban")
	if RealityClaim.should_reject_skeleton_spawn(get_tree(), RealityClaim.SKELETON_SCENE_PATH, dungeon_world):
		return _fail("dungeon skeleton spawn must be allowed without a pocket")

	var skeleton: Skeleton = load("res://monsters/skeleton/skeleton.tscn").instantiate()
	add_child(skeleton)
	skeleton.global_position = home_world
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_instance_valid(skeleton) or not skeleton._dying:
		return _fail("skeleton in Reality home must despawn")

	var goblin: Node2D = load("res://monsters/goblin.tscn").instantiate() as Node2D
	add_child(goblin)
	goblin.global_position = home_world
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_instance_valid(goblin) or goblin.get("_dying") == true:
		return _fail("goblin must not be banned from Reality")

	var dungeon_skel: Skeleton = load("res://monsters/skeleton/skeleton.tscn").instantiate()
	add_child(dungeon_skel)
	dungeon_skel.global_position = dungeon_world
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_instance_valid(dungeon_skel) or dungeon_skel._dying:
		return _fail("dungeon skeleton must live without Reality claim")
	var pocket_id: int = reality.spawn_pocket(dungeon_cell, Vector2i(2, 2), 8.0)
	if pocket_id < 0:
		return _fail("pocket over dungeon failed")
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_instance_valid(dungeon_skel) or not dungeon_skel._dying:
		return _fail("pocket covering a skeleton must despawn it")
	reality.expire_pocket(pocket_id)
	return true

func _check_snapshot(reality: RealityZone, interior: Rect2i) -> bool:
	var peer: RealityZone = load("res://zones/reality_zone.tscn").instantiate()
	peer.name = "PeerReality"
	add_child(peer)
	await get_tree().process_frame

	var cell: Vector2i = _east_unclaimed(reality, interior)
	var pocket_id: int = reality.spawn_pocket(cell, Vector2i(2, 2), 8.0)
	if pocket_id < 0:
		return _fail("snapshot pocket spawn failed")
	var payload: Dictionary = reality.build_claim_sync_payload()
	if payload.has("radius") or payload.has("base_radius"):
		return _fail("claim snapshot must not replicate circle radius")
	if payload.has("skeletons") or payload.has("skeleton_ids"):
		return _fail("claim snapshot must not resurrect skeletons")
	var packed: Array = payload.get("pockets", [])
	if packed.is_empty() or float(packed[0].get("remaining", 0.0)) <= 0.0:
		return _fail("snapshot missing live pocket remaining duration")
	if int(payload.get("home_w", 0)) <= 0:
		return _fail("snapshot missing home rect")

	peer.apply_claim_sync_payload(payload)
	await get_tree().process_frame
	if peer.home_rect != reality.home_rect:
		return _fail("peer home_rect %s != host %s" % [peer.home_rect, reality.home_rect])
	if not peer.is_claimed_cell(cell) or peer.overlay_kind_for_cell(cell) != "pocket":
		return _fail("peer must apply live pocket claim and overlay")
	if peer.winning_pocket_id(cell) != pocket_id:
		return _fail("peer pocket id %s != host %s" % [peer.winning_pocket_id(cell), pocket_id])
	var host_pockets: Node2D = reality.get_node("PocketOverlay")
	var peer_pockets: Node2D = peer.get_node("PocketOverlay")
	if peer_pockets.get_child_count() != host_pockets.get_child_count():
		return _fail("peer PocketOverlay count %s != host %s" % [peer_pockets.get_child_count(), host_pockets.get_child_count()])

	reality.expire_pocket(pocket_id)
	peer.apply_claim_sync_payload(reality.build_claim_sync_payload())
	await get_tree().process_frame
	if peer.is_claimed_cell(cell):
		return _fail("peer pocket claim survived expire snapshot")
	if not peer.is_claimed_cell(reality.home_rect.position):
		return _fail("peer home must survive expire snapshot")
	return true
