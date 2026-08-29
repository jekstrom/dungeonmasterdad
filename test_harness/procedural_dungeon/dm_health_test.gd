extends Node

const DM_SCENE := preload("res://dm/dm.tscn")
const ENTRANCE_POS := Vector2(640, 512)


func _ready() -> void:
	if not await _run():
		return
	print("DM health test passed")
	get_tree().quit(0)


func _run() -> bool:
	if not multiplayer.is_server():
		_fail("offline peer must be server")
		return false
	if not _assert_hud():
		return false
	if not await _assert_fantasy_then_health_then_respawn():
		return false
	return true


func _assert_hud() -> bool:
	Hud.turn_on()
	DmHud.turn_on()
	var health_bar: ColorRect = Hud.get_node_or_null("%DmHealthBar") as ColorRect
	var health_fill: ColorRect = Hud.get_node_or_null("%DmHealthFill") as ColorRect
	var health_label: Label = Hud.get_node_or_null("%DmHealthLabel") as Label
	var fantasy_bar: ColorRect = Hud.get_node_or_null("MarginContainer/HBoxContainer/FantasyColumn/FantasyBar") as ColorRect
	if health_bar == null or health_fill == null or health_label == null or fantasy_bar == null:
		_fail("health bar must sit under the fantasy bar")
		return false
	if health_bar.get_parent() != fantasy_bar.get_parent():
		_fail("health bar must share a column with the fantasy bar")
		return false
	if health_bar.get_index() <= fantasy_bar.get_index():
		_fail("health bar must be below the fantasy bar")
		return false
	if not health_bar.visible:
		_fail("DM health bar must be visible to the DM")
		return false
	if PlayerHud.get_node_or_null("%DmHealthBar") != null:
		_fail("Paper Pusher HUD must not show DM health")
		return false
	if health_label.text.find("HEALTH") < 0:
		_fail("health bar label missing, got %s" % health_label.text)
		return false
	return true


func _assert_fantasy_then_health_then_respawn() -> bool:
	var portal := Node2D.new()
	portal.name = "Entrance"
	portal.position = ENTRANCE_POS
	portal.add_to_group("entrance")
	add_child(portal)
	var dm: DM = DM_SCENE.instantiate() as DM
	dm.global_position = Vector2(100, 100)
	add_child(dm)
	await get_tree().process_frame
	await get_tree().process_frame
	DmManager.dm = dm
	dm.hitpoints = 6
	dm.max_hp = 6
	dm.invulnerable = false
	dm.set("_dead", false)
	DmManager.fantasy_level = 4
	DmManager.broadcast_health(6, 6)
	dm.apply_fantasy_hit(2)
	if int(DmManager.fantasy_level) != 2:
		_fail("hit with fantasy > 0 must drain fantasy, got %s" % DmManager.fantasy_level)
		return false
	if int(dm.hitpoints) != 6:
		_fail("hit with fantasy > 0 must not drain health, got %s" % dm.hitpoints)
		return false
	dm.invulnerable = false
	DmManager.fantasy_level = 0
	dm.apply_fantasy_hit(2)
	if int(DmManager.fantasy_level) != 0:
		_fail("hit at 0 fantasy must not change fantasy")
		return false
	if int(dm.hitpoints) != 4:
		_fail("hit at 0 fantasy must reduce health by the same amount, got %s" % dm.hitpoints)
		return false
	var label: Label = Hud.get_node_or_null("%DmHealthLabel") as Label
	if label and label.text != "HEALTH 4/6":
		_fail("health HUD must follow hits, got %s" % label.text)
		return false
	dm.invulnerable = false
	dm.apply_fantasy_hit(4)
	await get_tree().process_frame
	if not bool(dm.get("_dead")):
		_fail("health 0 must down the DM")
		return false
	if int(dm.hitpoints) != 0:
		_fail("downed DM health must be 0")
		return false
	var remaining: float = float(dm.get("_respawn_remaining"))
	if remaining < 9.0 or remaining > 10.01:
		_fail("respawn delay must be 10s, got %s" % remaining)
		return false
	var overlay: Control = DmHud.get_node_or_null("%RespawnOverlay") as Control
	var countdown: Label = DmHud.get_node_or_null("%DmRespawnCountdown") as Label
	if overlay == null or not overlay.visible or countdown == null:
		_fail("DM must see a respawn countdown")
		return false
	if countdown.text.find("RESPAWN IN") < 0:
		_fail("countdown text missing, got %s" % countdown.text)
		return false
	if dm.global_position.distance_to(ENTRANCE_POS) < 8.0:
		_fail("DM must not teleport until the countdown finishes")
		return false
	dm.call("_tick_respawn", 10.0)
	await get_tree().process_frame
	if bool(dm.get("_dead")):
		_fail("DM must respawn after 10s")
		return false
	if int(dm.hitpoints) != 6:
		_fail("respawn must restore health, got %s" % dm.hitpoints)
		return false
	if dm.global_position.distance_to(ENTRANCE_POS) > 8.0:
		_fail("DM must respawn at the dungeon entrance, got %s" % dm.global_position)
		return false
	if overlay.visible:
		_fail("countdown must hide after respawn")
		return false
	dm.queue_free()
	portal.queue_free()
	await get_tree().process_frame
	return true


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
