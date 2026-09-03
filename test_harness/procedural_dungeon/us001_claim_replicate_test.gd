extends Node

func _ready() -> void:
	Zone.debug_claim_overlays = true
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

	var host: RealityZone = load("res://zones/reality_zone.tscn").instantiate()
	host.name = "HostReality"
	host.add_to_group("RealityZone")
	add_child(host)
	await get_tree().process_frame

	var peer: RealityZone = load("res://zones/reality_zone.tscn").instantiate()
	peer.name = "PeerReality"
	add_child(peer)
	await get_tree().process_frame

	var outside_home := Vector2i(interior.end.x - 3, interior.position.y + 1)
	if host.home_rect.has_point(outside_home):
		outside_home = Vector2i(interior.end.x - 1, interior.end.y - 1)

	var pocket_id: int = host.spawn_pocket(outside_home, Vector2i(2, 2), 8.0)
	if pocket_id < 0:
		push_error("US-001 T008: host pocket spawn failed")
		get_tree().quit(1)
		return

	var payload: Dictionary = host.build_claim_sync_payload()
	if payload.has("radius") or payload.has("base_radius"):
		push_error("US-001 T008: claim snapshot must not replicate circle radius")
		get_tree().quit(1)
		return
	if payload.has("skeletons") or payload.has("skeleton_ids"):
		push_error("US-001 T008: claim snapshot must not resurrect skeletons")
		get_tree().quit(1)
		return
	var packed_pockets: Array = payload.get("pockets", [])
	if packed_pockets.is_empty():
		push_error("US-001 T008: snapshot missing live pocket")
		get_tree().quit(1)
		return
	if float(packed_pockets[0].get("remaining", 0.0)) <= 0.0:
		push_error("US-001 T008: live pocket remaining duration must be > 0")
		get_tree().quit(1)
		return
	if int(payload.get("home_w", 0)) <= 0 or int(payload.get("home_h", 0)) <= 0:
		push_error("US-001 T008: snapshot missing home rect")
		get_tree().quit(1)
		return

	peer.apply_claim_sync_payload(payload)
	await get_tree().process_frame

	if peer.home_rect != host.home_rect:
		push_error("US-001 T008: peer home_rect %s != host %s" % [peer.home_rect, host.home_rect])
		get_tree().quit(1)
		return
	if not peer.is_claimed_cell(host.home_rect.position):
		push_error("US-001 T008: peer must claim host home cell")
		get_tree().quit(1)
		return
	if not peer.is_claimed_cell(outside_home):
		push_error("US-001 T008: peer must claim live pocket cell")
		get_tree().quit(1)
		return
	if peer.overlay_kind_for_cell(outside_home) != "pocket":
		push_error("US-001 T008: peer pocket overlay kind mismatch")
		get_tree().quit(1)
		return
	if peer.overlay_kind_for_cell(host.home_rect.position) != "home":
		push_error("US-001 T008: peer home overlay kind mismatch")
		get_tree().quit(1)
		return
	if peer.winning_pocket_id(outside_home) != pocket_id:
		push_error("US-001 T008: peer pocket id %s != host %s" % [peer.winning_pocket_id(outside_home), pocket_id])
		get_tree().quit(1)
		return

	var host_home_overlay: Node2D = host.get_node_or_null("HomeOverlay")
	var peer_home_overlay: Node2D = peer.get_node_or_null("HomeOverlay")
	if host_home_overlay == null or peer_home_overlay == null:
		push_error("US-001 T008: HomeOverlay missing")
		get_tree().quit(1)
		return
	if peer_home_overlay.get_child_count() != host_home_overlay.get_child_count():
		push_error("US-001 T008: HomeOverlay count peer %s host %s" % [peer_home_overlay.get_child_count(), host_home_overlay.get_child_count()])
		get_tree().quit(1)
		return
	var host_pocket_overlay: Node2D = host.get_node("PocketOverlay")
	var peer_pocket_overlay: Node2D = peer.get_node("PocketOverlay")
	if peer_pocket_overlay.get_child_count() != host_pocket_overlay.get_child_count():
		push_error("US-001 T008: PocketOverlay count peer %s host %s" % [peer_pocket_overlay.get_child_count(), host_pocket_overlay.get_child_count()])
		get_tree().quit(1)
		return
	if peer_pocket_overlay.get_child_count() <= 0:
		push_error("US-001 T008: peer PocketOverlay empty after apply")
		get_tree().quit(1)
		return

	if not host.expire_pocket(pocket_id):
		push_error("US-001 T008: host expire failed")
		get_tree().quit(1)
		return
	var expired_payload: Dictionary = host.build_claim_sync_payload()
	if not expired_payload.get("pockets", []).is_empty():
		push_error("US-001 T008: snapshot still has pockets after expire")
		get_tree().quit(1)
		return
	peer.apply_claim_sync_payload(expired_payload)
	await get_tree().process_frame
	if peer.is_claimed_cell(outside_home):
		push_error("US-001 T008: peer pocket claim survived expire snapshot")
		get_tree().quit(1)
		return
	if peer.get_node("PocketOverlay").get_child_count() != 0:
		push_error("US-001 T008: peer PocketOverlay not cleared after expire snapshot")
		get_tree().quit(1)
		return
	if not peer.is_claimed_cell(host.home_rect.position):
		push_error("US-001 T008: peer home must survive expire snapshot")
		get_tree().quit(1)
		return

	PlayerManager.reality_level = 0
	print("US-001 T008 claim replicate test passed")
	get_tree().quit(0)
