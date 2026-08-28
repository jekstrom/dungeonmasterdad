extends Node

func _ready() -> void:
	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	add_child(level)
	await get_tree().process_frame

	var interior := Rect2i(0, 0, 16, 10)
	var dungeon := Rect2i(8, 2, 8, 6)
	level.apply_map_interior(interior, dungeon)
	await get_tree().process_frame

	var reality: RealityZone = load("res://zones/reality_zone.tscn").instantiate()
	var fantasy: Zone = load("res://zones/fantasy_zone.tscn").instantiate()
	add_child(reality)
	add_child(fantasy)
	await get_tree().process_frame

	DmManager.fantasy_level = 0
	fantasy.clip_home_to_interior()
	if fantasy.home_rect.size.x <= 0 or fantasy.home_rect.size.y <= 0:
		_fail("US-016 T006: Fantasy home_rect missing at level 0")
		return
	var before: Rect2i = fantasy.home_rect
	var reality_before: Rect2i = reality.home_rect
	var before_area: int = before.size.x * before.size.y

	var d6: ItemData = load("res://pickups/d6.tres") as ItemData
	if d6 == null:
		_fail("US-016 T006: d6.tres missing")
		return
	d6.use()
	await get_tree().process_frame
	fantasy.clip_home_to_interior()

	if fantasy.home_rect.size.x <= 0 or fantasy.home_rect.size.y <= 0:
		_fail("US-016 T006: Fantasy home_rect must stay a rectangle")
		return
	if not interior.encloses(fantasy.home_rect):
		_fail("US-016 T006: grown Fantasy home must stay inside interior")
		return
	var after_area: int = fantasy.home_rect.size.x * fantasy.home_rect.size.y
	if after_area <= before_area and fantasy.home_rect == before:
		_fail("US-016 T006: d6 must grow the Fantasy home rectangle")
		return
	if reality.home_rect != reality_before:
		_fail("US-016 T006: Reality home must not grow from a die")
		return

	print("US-016 T006 fantasy home growth test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
