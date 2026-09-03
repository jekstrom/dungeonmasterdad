extends Node

func _ready() -> void:
	Zone.debug_claim_overlays = true
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

	var fantasy: FantasyZone = load("res://zones/fantasy_zone.tscn").instantiate()
	add_child(fantasy)
	await get_tree().process_frame

	var home_cell: Vector2i = fantasy.home_rect.position
	var outside_home := Vector2i(interior.position.x + 1, interior.position.y + 1)
	if fantasy.home_rect.has_point(outside_home):
		outside_home = Vector2i(interior.position.x, interior.position.y)
	if fantasy.is_claimed_cell(outside_home):
		push_error("US-003 T004: west cell must start unclaimed")
		get_tree().quit(1)
		return
	if not fantasy.is_claimed_cell(home_cell):
		push_error("US-003 T004: home cell must be claimed")
		get_tree().quit(1)
		return

	var degenerate: int = fantasy.spawn_pocket(Vector2i(4, 4), Vector2i(0, 3), 8.0)
	if degenerate != -1:
		push_error("US-003 T004: zero-size pocket must be rejected")
		get_tree().quit(1)
		return

	var overflow_id: int = fantasy.spawn_pocket(Vector2i(-4, -2), Vector2i(6, 4), 8.0)
	if overflow_id < 0:
		push_error("US-003 T004: overflow pocket should clip, not reject")
		get_tree().quit(1)
		return
	var overflow: Dictionary = fantasy.get_pocket(overflow_id)
	var overflow_rect: Rect2i = overflow["rect"]
	if overflow_rect.position.x < 0 or overflow_rect.position.y < 0:
		push_error("US-003 T004: clipped pocket left interior %s" % overflow_rect)
		get_tree().quit(1)
		return
	if overflow_rect.end.x > interior.end.x or overflow_rect.end.y > interior.end.y:
		push_error("US-003 T004: clipped pocket overflowed interior %s" % overflow_rect)
		get_tree().quit(1)
		return

	var pocket_a: int = fantasy.spawn_pocket(outside_home, Vector2i(2, 2), 8.0)
	if pocket_a < 0:
		push_error("US-003 T004: pocket spawn failed")
		get_tree().quit(1)
		return
	if not fantasy.is_claimed_cell(outside_home):
		push_error("US-003 T004: pocket cell must be Fantasy-claimed")
		get_tree().quit(1)
		return
	if not fantasy.is_claimed_world(DungeonGrid.to_world_center(outside_home)):
		push_error("US-003 T004: world query must follow pocket claim")
		get_tree().quit(1)
		return
	if fantasy.overlay_kind_for_cell(outside_home) != "pocket":
		push_error("US-003 T004: pocket cell must use pocket overlay")
		get_tree().quit(1)
		return
	var pocket_overlay: Node2D = fantasy.get_node_or_null("PocketOverlay")
	if pocket_overlay == null or pocket_overlay.get_child_count() <= 0:
		push_error("US-003 T004: PocketOverlay missing sprites")
		get_tree().quit(1)
		return
	var pocket_sprite: Sprite2D = pocket_overlay.get_child(0) as Sprite2D
	if pocket_sprite == null or str(pocket_sprite.texture.resource_path).find("fantasy_pocket_overlay.png") == -1:
		push_error("US-003 T004: pocket overlay must use fantasy_pocket_overlay.png")
		get_tree().quit(1)
		return

	var pocket_b: int = fantasy.spawn_pocket(outside_home, Vector2i(2, 2), 8.0)
	if fantasy.winning_pocket_id(outside_home) != pocket_b:
		push_error("US-003 T004: newer pocket must win overlap, got %s want %s" % [fantasy.winning_pocket_id(outside_home), pocket_b])
		get_tree().quit(1)
		return

	if not fantasy.expire_pocket(pocket_b):
		push_error("US-003 T004: expire newer pocket failed")
		get_tree().quit(1)
		return
	if fantasy.winning_pocket_id(outside_home) != pocket_a:
		push_error("US-003 T004: older pocket should remain after newer expires")
		get_tree().quit(1)
		return

	fantasy.expire_pocket(pocket_a)
	fantasy.expire_pocket(overflow_id)
	if fantasy.is_claimed_cell(outside_home):
		push_error("US-003 T004: expired pocket must restore unclaimed ground")
		get_tree().quit(1)
		return
	if fantasy.overlay_kind_for_cell(outside_home) != "":
		push_error("US-003 T004: expired pocket overlay must clear")
		get_tree().quit(1)
		return
	if fantasy.get_node("PocketOverlay").get_child_count() != 0:
		push_error("US-003 T004: PocketOverlay should be empty after expire")
		get_tree().quit(1)
		return
	if not fantasy.is_claimed_cell(home_cell):
		push_error("US-003 T004: home claim must survive pocket expire")
		get_tree().quit(1)
		return

	var timed: int = fantasy.spawn_pocket(outside_home, Vector2i(1, 1), 0.05)
	if timed < 0:
		push_error("US-003 T004: short-duration pocket spawn failed")
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.2).timeout
	if fantasy.is_claimed_cell(outside_home):
		push_error("US-003 T004: timer expire did not restore claim")
		get_tree().quit(1)
		return

	DmManager.fantasy_level = 0
	print("US-003 T004 pocket contract test passed")
	get_tree().quit(0)
