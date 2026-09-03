extends Node

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

	var host: FantasyZone = load("res://zones/fantasy_zone.tscn").instantiate()
	host.name = "HostFantasy"
	add_child(host)
	var peer: FantasyZone = load("res://zones/fantasy_zone.tscn").instantiate()
	peer.name = "PeerFantasy"
	add_child(peer)
	await get_tree().process_frame
	await get_tree().physics_frame

	var home_world: Vector2 = DungeonGrid.to_world_center(host.home_rect.position)
	var paper := CharacterBody2D.new()
	paper.name = "LateJoinPaper"
	paper.add_to_group("players")
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	shape_node.shape = shape
	paper.add_child(shape_node)
	paper.collision_layer = 1
	paper.collision_mask = 16
	add_child(paper)
	paper.global_position = home_world
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_instance_valid(paper):
		push_error("US-003 T009: Paper Pusher must remain alive inside Fantasy")
		get_tree().quit(1)
		return
	if not host.is_claimed_world(paper.global_position):
		push_error("US-003 T009: host must not push the Paper Pusher out of Fantasy")
		get_tree().quit(1)
		return
	if not paper.global_position.is_equal_approx(home_world):
		push_error("US-003 T009: Paper Pusher must keep the Fantasy home cell")
		get_tree().quit(1)
		return

	var outside_home := Vector2i(interior.position.x + 1, interior.position.y + 1)
	if host.home_rect.has_point(outside_home) or host.is_claimed_cell(outside_home):
		outside_home = Vector2i(interior.position.x, interior.position.y)
	var pocket_id: int = host.spawn_pocket(outside_home, Vector2i(2, 2), 8.0)
	if pocket_id < 0:
		push_error("US-003 T009: host pocket spawn failed")
		get_tree().quit(1)
		return

	var payload: Dictionary = host.build_claim_sync_payload()
	if payload.has("radius") or payload.has("base_radius"):
		push_error("US-003 T009: claim snapshot must not replicate circle radius")
		get_tree().quit(1)
		return
	var packed_pockets: Array = payload.get("pockets", [])
	if packed_pockets.is_empty():
		push_error("US-003 T009: snapshot missing live pocket")
		get_tree().quit(1)
		return
	if float(packed_pockets[0].get("remaining", 0.0)) <= 0.0:
		push_error("US-003 T009: live pocket remaining duration must be > 0")
		get_tree().quit(1)
		return
	if int(payload.get("home_w", 0)) <= 0 or int(payload.get("home_h", 0)) <= 0:
		push_error("US-003 T009: snapshot missing home rect")
		get_tree().quit(1)
		return
	if payload.has("players") and not payload.get("players", []).is_empty():
		push_error("US-003 T009: claim snapshot must not pack Paper Pusher displacement")
		get_tree().quit(1)
		return

	peer.apply_claim_sync_payload(payload)
	await get_tree().process_frame
	await get_tree().physics_frame

	if peer.home_rect != host.home_rect:
		push_error("US-003 T009: peer home_rect %s != host %s" % [peer.home_rect, host.home_rect])
		get_tree().quit(1)
		return
	if not peer.is_claimed_cell(host.home_rect.position):
		push_error("US-003 T009: peer must claim host home cell")
		get_tree().quit(1)
		return
	if not peer.is_claimed_cell(outside_home):
		push_error("US-003 T009: peer must claim live pocket cell")
		get_tree().quit(1)
		return
	if peer.overlay_kind_for_cell(outside_home) != "pocket":
		push_error("US-003 T009: peer pocket overlay kind mismatch")
		get_tree().quit(1)
		return
	if peer.overlay_kind_for_cell(host.home_rect.position) != "home":
		push_error("US-003 T009: peer home overlay kind mismatch")
		get_tree().quit(1)
		return
	if peer.winning_pocket_id(outside_home) != pocket_id:
		push_error("US-003 T009: peer pocket id %s != host %s" % [peer.winning_pocket_id(outside_home), pocket_id])
		get_tree().quit(1)
		return
	if not is_instance_valid(paper) or not host.is_claimed_world(paper.global_position):
		push_error("US-003 T009: late join must not shove a Paper Pusher out of Fantasy")
		get_tree().quit(1)
		return
	if not paper.global_position.is_equal_approx(home_world):
		push_error("US-003 T009: late-join snapshot must not teleport the Paper Pusher")
		get_tree().quit(1)
		return

	var host_home_overlay: Node2D = host.get_node_or_null("HomeOverlay")
	var peer_home_overlay: Node2D = peer.get_node_or_null("HomeOverlay")
	if host_home_overlay == null or peer_home_overlay == null:
		push_error("US-003 T009: HomeOverlay missing")
		get_tree().quit(1)
		return
	if peer_home_overlay.get_child_count() != host_home_overlay.get_child_count():
		push_error("US-003 T009: HomeOverlay count peer %s host %s" % [peer_home_overlay.get_child_count(), host_home_overlay.get_child_count()])
		get_tree().quit(1)
		return
	var host_pocket_overlay: Node2D = host.get_node("PocketOverlay")
	var peer_pocket_overlay: Node2D = peer.get_node("PocketOverlay")
	if peer_pocket_overlay.get_child_count() != host_pocket_overlay.get_child_count():
		push_error("US-003 T009: PocketOverlay count peer %s host %s" % [peer_pocket_overlay.get_child_count(), host_pocket_overlay.get_child_count()])
		get_tree().quit(1)
		return
	if peer_pocket_overlay.get_child_count() <= 0:
		push_error("US-003 T009: peer PocketOverlay empty after apply")
		get_tree().quit(1)
		return
	if peer.get_node_or_null("Exclusion") != null or host.get_node_or_null("Exclusion") != null:
		push_error("US-003 T009: Exclusion wall must not rebuild from snapshot")
		get_tree().quit(1)
		return

	if not host.expire_pocket(pocket_id):
		push_error("US-003 T009: host expire failed")
		get_tree().quit(1)
		return
	var expired_payload: Dictionary = host.build_claim_sync_payload()
	if not expired_payload.get("pockets", []).is_empty():
		push_error("US-003 T009: snapshot still has pockets after expire")
		get_tree().quit(1)
		return
	peer.apply_claim_sync_payload(expired_payload)
	await get_tree().process_frame
	if peer.is_claimed_cell(outside_home):
		push_error("US-003 T009: peer pocket claim survived expire snapshot")
		get_tree().quit(1)
		return
	if peer.get_node("PocketOverlay").get_child_count() != 0:
		push_error("US-003 T009: peer PocketOverlay not cleared after expire snapshot")
		get_tree().quit(1)
		return
	if not peer.is_claimed_cell(host.home_rect.position):
		push_error("US-003 T009: peer home must survive expire snapshot")
		get_tree().quit(1)
		return
	if not is_instance_valid(paper) or not host.is_claimed_world(paper.global_position):
		push_error("US-003 T009: Paper Pusher must stay alive inside Fantasy after expire snapshot")
		get_tree().quit(1)
		return

	DmManager.fantasy_level = 0
	print("US-003 T009 claim replicate test passed")
	get_tree().quit(0)
