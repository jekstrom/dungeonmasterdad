extends Node

func _ready() -> void:
	PlayerManager.reality_level = 0
	DmManager.fantasy_level = 0
	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	level.add_to_group("level_manager")
	add_child(level)
	await get_tree().process_frame
	await get_tree().process_frame

	var ambience: ZoneAmbientVfx = level.get_node_or_null("ZoneAmbientVfx")
	if ambience == null:
		push_error("US-026 T001: ZoneAmbientVfx missing from LevelManager")
		get_tree().quit(1)
		return

	if ambience.is_physics_processing():
		push_error("US-026 T001: physics must stay off when claims are empty")
		get_tree().quit(1)
		return
	if ambience.is_processing():
		push_error("US-026 T001: process must sleep when both claims are empty")
		get_tree().quit(1)
		return
	if ambience.has_replicated_emitting():
		push_error("US-026 T004: ambient owner must not have MultiplayerSynchronizer")
		get_tree().quit(1)
		return

	if ambience.dust_strip_path() != "res://sprites/reality_dust.png":
		push_error("US-026 T002: dust strip must be reality_dust.png, got %s" % ambience.dust_strip_path())
		get_tree().quit(1)
		return
	if ambience.sparkle_strip_path() != "res://sprites/fantasy_sparkle.png":
		push_error("US-026 T003: sparkle strip must be fantasy_sparkle.png, got %s" % ambience.sparkle_strip_path())
		get_tree().quit(1)
		return
	if ambience.dust_strip_path() == "res://sprites/reality_drift_puff.png":
		push_error("US-026 T002: ambience must not loop reality_drift_puff.png")
		get_tree().quit(1)
		return
	if ambience.sparkle_strip_path() == "res://sprites/fantasy_drift_puff.png":
		push_error("US-026 T003: ambience must not loop fantasy_drift_puff.png")
		get_tree().quit(1)
		return
	if ambience.sparkle_strip_path() == "res://sprites/sparks.png":
		push_error("US-026 T003: do not use sparks.png for Fantasy sparkles")
		get_tree().quit(1)
		return
	if not ResourceLoader.exists(ambience.dust_strip_path()):
		push_error("US-026 T002: missing reality_dust.png")
		get_tree().quit(1)
		return
	if not ResourceLoader.exists(ambience.sparkle_strip_path()):
		push_error("US-026 T003: missing fantasy_sparkle.png")
		get_tree().quit(1)
		return

	var interior := Rect2i(0, 0, 16, 10)
	var dungeon := Rect2i(8, 2, 8, 6)
	level.apply_map_interior(interior, dungeon)
	await get_tree().process_frame
	level.rebuild_outside_fill()
	await get_tree().process_frame

	var reality_drift: RealityTileDrift = level.get_node_or_null("RealityTileDrift")
	var fantasy_drift: FantasyTileDrift = level.get_node_or_null("FantasyTileDrift")
	if reality_drift:
		reality_drift.set_physics_process(false)
		reality_drift.clear_schedules()
	if fantasy_drift:
		fantasy_drift.set_physics_process(false)
		fantasy_drift.clear_schedules()

	var reality: RealityZone = load("res://zones/reality_zone.tscn").instantiate()
	var fantasy: FantasyZone = load("res://zones/fantasy_zone.tscn").instantiate()
	add_child(reality)
	add_child(fantasy)
	await get_tree().process_frame
	await get_tree().process_frame
	ambience.rebuild_candidates()

	if reality.home_rect.size.x <= 0 or reality.home_rect.size.y <= 0:
		push_error("US-026 T001: Reality home missing")
		get_tree().quit(1)
		return
	if fantasy.home_rect.size.x <= 0 or fantasy.home_rect.size.y <= 0:
		push_error("US-026 T001: Fantasy home missing")
		get_tree().quit(1)
		return

	var reality_cell: Vector2i = reality.home_rect.position
	var fantasy_cell: Vector2i = fantasy.home_rect.position
	var quiet_cell: Vector2i = _unclaimed_cell(interior, reality, fantasy)
	if quiet_cell.x < interior.position.x:
		push_error("US-026 T001: need an unclaimed cell")
		get_tree().quit(1)
		return

	if not ambience.is_dust_candidate(reality_cell):
		push_error("US-026 T001: Reality-claimed nearby cell must be a dust candidate (%s)" % reality_cell)
		get_tree().quit(1)
		return
	if ambience.is_sparkle_candidate(reality_cell):
		push_error("US-026 T002: Reality cell must not be a sparkle candidate")
		get_tree().quit(1)
		return
	if not ambience.is_sparkle_candidate(fantasy_cell):
		push_error("US-026 T001: Fantasy-claimed nearby cell must be a sparkle candidate (%s)" % fantasy_cell)
		get_tree().quit(1)
		return
	if ambience.is_dust_candidate(fantasy_cell):
		push_error("US-026 T003: Fantasy cell must not be a dust candidate")
		get_tree().quit(1)
		return
	if ambience.is_dust_candidate(quiet_cell) or ambience.is_sparkle_candidate(quiet_cell):
		push_error("US-026 T001: unclaimed cell must be neither dust nor sparkle (%s)" % quiet_cell)
		get_tree().quit(1)
		return

	if dungeon.size.x > 0 and fantasy.home_rect.has_point(dungeon.position):
		if not ambience.is_sparkle_candidate(dungeon.position):
			push_error("US-026 T001: dungeon-claimed Fantasy cell MAY be a sparkle candidate")
			get_tree().quit(1)
			return
		if ambience.is_dust_candidate(dungeon.position):
			push_error("US-026 T001: dungeon Fantasy cell must not emit Reality dust")
			get_tree().quit(1)
			return

	var dust_pop: AnimatedSprite2D = ambience.play_pop(reality_cell)
	if dust_pop == null:
		push_error("US-026 T002: Reality dust pop failed on a dust candidate")
		get_tree().quit(1)
		return
	var dust_path: String = _atlas_path(dust_pop)
	if dust_path.find("reality_dust.png") == -1:
		push_error("US-026 T002: dust pop must use reality_dust.png, got %s" % dust_path)
		get_tree().quit(1)
		return
	if dust_path.find("reality_drift_puff.png") != -1:
		push_error("US-026 T002: dust pop must not use reality_drift_puff.png")
		get_tree().quit(1)
		return

	var sparkle_pop: AnimatedSprite2D = ambience.play_pop(fantasy_cell)
	if sparkle_pop == null:
		push_error("US-026 T003: Fantasy sparkle pop failed on a sparkle candidate")
		get_tree().quit(1)
		return
	var sparkle_path: String = _atlas_path(sparkle_pop)
	if sparkle_path.find("fantasy_sparkle.png") == -1:
		push_error("US-026 T003: sparkle pop must use fantasy_sparkle.png, got %s" % sparkle_path)
		get_tree().quit(1)
		return
	if sparkle_path.find("fantasy_drift_puff.png") != -1 or sparkle_path.find("sparks.png") != -1:
		push_error("US-026 T003: sparkle pop must not use convert puff or sparks.png")
		get_tree().quit(1)
		return

	if ambience.play_pop(quiet_cell) != null:
		push_error("US-026 T001: unclaimed cell must not emit a pop")
		get_tree().quit(1)
		return
	if ambience.play_pop(reality_cell) != null and ambience.is_sparkle_candidate(reality_cell):
		push_error("US-026 T003: must not emit Fantasy sparkles on Reality cells")
		get_tree().quit(1)
		return

	if ambience.has_replicated_emitting():
		push_error("US-026 T004: pop sprites must not add MultiplayerSynchronizer")
		get_tree().quit(1)
		return
	if _has_particle_emitting_sync(ambience):
		push_error("US-026 T004: no replicated particle-emitting property on ambient owner")
		get_tree().quit(1)
		return

	if ambience.is_physics_processing():
		push_error("US-026 T001: physics must stay off while ambience is running")
		get_tree().quit(1)
		return
	if not ambience.is_processing():
		push_error("US-026 T001: process should run while claimed candidates exist")
		get_tree().quit(1)
		return

	var rebuilds_before: int = ambience.rebuild_count
	for _i in range(5):
		await get_tree().physics_frame
	if ambience.rebuild_count != rebuilds_before:
		push_error("US-026 T001: claim set rebuilt without a claim/map signal (%d -> %d)" % [rebuilds_before, ambience.rebuild_count])
		get_tree().quit(1)
		return

	var pocket_id: int = reality.spawn_pocket(quiet_cell, Vector2i(2, 2), 8.0)
	if pocket_id < 0:
		push_error("US-026 T001: Reality pocket spawn failed")
		get_tree().quit(1)
		return
	await get_tree().process_frame
	if ambience.rebuild_count <= rebuilds_before:
		push_error("US-026 T001: claim change must rebuild candidates (no full-map physics scan)")
		get_tree().quit(1)
		return
	if not ambience.is_dust_candidate(quiet_cell):
		push_error("US-026 T001: Reality pocket cell must become a dust candidate")
		get_tree().quit(1)
		return
	if ambience.is_sparkle_candidate(quiet_cell):
		push_error("US-026 T001: Reality pocket must not be a sparkle candidate")
		get_tree().quit(1)
		return
	if not reality.expire_pocket(pocket_id):
		push_error("US-026 T001: Reality pocket expire failed")
		get_tree().quit(1)
		return
	await get_tree().process_frame
	if ambience.is_dust_candidate(quiet_cell) or ambience.is_sparkle_candidate(quiet_cell):
		push_error("US-026 T001: expired pocket cell must go quiet")
		get_tree().quit(1)
		return

	var fantasy_pocket: int = fantasy.spawn_pocket(quiet_cell, Vector2i(2, 2), 8.0)
	if fantasy_pocket < 0:
		push_error("US-026 T001: Fantasy pocket spawn failed")
		get_tree().quit(1)
		return
	await get_tree().process_frame
	if not ambience.is_sparkle_candidate(quiet_cell):
		push_error("US-026 T001: Fantasy pocket cell must become a sparkle candidate")
		get_tree().quit(1)
		return
	if ambience.is_dust_candidate(quiet_cell):
		push_error("US-026 T003: Fantasy pocket must not emit Reality dust")
		get_tree().quit(1)
		return
	fantasy.expire_pocket(fantasy_pocket)
	await get_tree().process_frame

	# Occupancy unchanged: Paper Pusher walks Fantasy (US-003 T011).
	if fantasy.get_node_or_null("Exclusion") != null:
		push_error("US-026 T005: Fantasy Exclusion wall must not exist (US-003 T011)")
		get_tree().quit(1)
		return
	var home_world: Vector2 = DungeonGrid.to_world_center(fantasy_cell)
	var outside_world: Vector2 = DungeonGrid.to_world_center(quiet_cell)
	if fantasy.is_claimed_world(outside_world):
		push_error("US-026 T005: occupancy fixture cell must start unclaimed")
		get_tree().quit(1)
		return
	var paper := _make_body()
	paper.add_to_group("players")
	add_child(paper)
	paper.global_position = outside_world
	await get_tree().physics_frame
	await get_tree().physics_frame
	if paper.test_move(paper.transform, home_world - paper.global_position):
		push_error("US-026 T005: Paper Pusher must walk into Fantasy, not stop at a wall (US-003 T011)")
		get_tree().quit(1)
		return
	paper.global_position = home_world
	await get_tree().physics_frame
	if not fantasy.is_claimed_world(paper.global_position):
		push_error("US-026 T005: Paper Pusher inside Fantasy home must not be snapped out (US-003 T011)")
		get_tree().quit(1)
		return
	if not paper.global_position.is_equal_approx(home_world):
		push_error("US-026 T005: Paper Pusher must keep the home cell they were placed on (US-003 T011)")
		get_tree().quit(1)
		return
	if not reality.is_claimed_world(DungeonGrid.to_world_center(reality_cell)):
		push_error("US-026 T005: Reality occupancy query must still cover home")
		get_tree().quit(1)
		return

	PlayerManager.reality_level = 0
	DmManager.fantasy_level = 0
	print("US-026 T001-T005 ambient VFX headless test passed")
	print("US-026 two-window play pass not run (QA owns it)")
	get_tree().quit(0)

func _unclaimed_cell(interior: Rect2i, reality: RealityZone, fantasy: FantasyZone) -> Vector2i:
	for y in range(interior.position.y, interior.end.y):
		for x in range(interior.position.x, interior.end.x):
			var cell := Vector2i(x, y)
			if reality.is_claimed_cell(cell) or fantasy.is_claimed_cell(cell):
				continue
			return cell
	return Vector2i(-999, -999)

func _atlas_path(sprite: AnimatedSprite2D) -> String:
	if sprite == null or sprite.sprite_frames == null:
		return ""
	if not sprite.sprite_frames.has_animation("pop"):
		return ""
	var tex: Texture2D = sprite.sprite_frames.get_frame_texture("pop", 0)
	if tex is AtlasTexture:
		var atlas: Texture2D = (tex as AtlasTexture).atlas
		if atlas:
			return str(atlas.resource_path)
	if tex:
		return str(tex.resource_path)
	return ""

func _has_particle_emitting_sync(node: Node) -> bool:
	if node.get_class() == "MultiplayerSynchronizer":
		return true
	for child in node.get_children():
		if _has_particle_emitting_sync(child):
			return true
	return false

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
