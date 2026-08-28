extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	change_scene_to_file("res://playground.tscn")
	await process_frame
	await process_frame

	var peer := ENetMultiplayerPeer.new()
	var err: int = peer.create_server(42111)
	if err != OK:
		push_error("shadow trail test: create_server failed %s" % err)
		quit(1)
		return
	root.multiplayer.multiplayer_peer = peer
	await process_frame

	var playground: Node = current_scene
	if playground == null:
		push_error("shadow trail test: playground missing")
		quit(1)
		return

	var container: Node = playground.find_child("SnakeTrailContainer", true, false)
	if container == null:
		push_error("shadow trail test: SnakeTrailContainer missing")
		quit(1)
		return

	var player_scene: PackedScene = load("res://player/player.tscn")
	var player: Node = player_scene.instantiate()
	player.name = "2"
	player.position = Vector2(200, 200)
	player.add_to_group("players")
	playground.add_child(player, true)
	await process_frame

	var dm_unlocks: Node = root.get_node("DmUnlocks")
	var trail_manager: Node = root.get_node("TrailManager")
	var death_system: Node = root.get_node("DeathSystem")
	dm_unlocks.unlock("shadow_zone")
	for i in range(8):
		await process_frame

	if not bool(trail_manager.get("shadow_mode_active")):
		push_error("shadow trail test: shadow_mode_active is false")
		quit(1)
		return

	var shadows: Dictionary = trail_manager.get("shadows")
	if not shadows.has(2) or shadows[2].size() != 2:
		push_error("shadow trail test: expected 2 trail records, got %s" % shadows)
		quit(1)
		return

	var trail_count: int = 0
	var textured: int = 0
	for child in container.get_children():
		if not str(child.name).begins_with("trail_2_"):
			continue
		trail_count += 1
		var sprite := child.get_node_or_null("Sprite2D") as Sprite2D
		if sprite and sprite.texture:
			textured += 1

	if trail_count != 2:
		push_error("shadow trail test: expected 2 trail nodes, got %d" % trail_count)
		quit(1)
		return
	if textured != 2:
		push_error("shadow trail test: expected 2 textured sprites, got %d" % textured)
		quit(1)
		return

	if int(player.get("hitpoints")) < int(player.get("max_hp")):
		push_error("shadow trail test: player took damage from own trail")
		quit(1)
		return
	if death_system.get("active_death_timers") is Dictionary and (death_system.get("active_death_timers") as Dictionary).has(2):
		push_error("shadow trail test: player died from own trail")
		quit(1)
		return

	print("shadow trail test passed: trail_count=", trail_count, " textured=", textured)
	quit(0)
