extends Node

const Planner = preload("res://scripts/procedural_dungeon/pickup_spawn_planner.gd")
const Catalog = preload("res://dm/dm_ability_catalog.gd")

var _spawn_knight_count: int = 0

func _ready() -> void:
	if not DmManager.spawn_knight_cast.is_connected(_on_spawn_knight):
		DmManager.spawn_knight_cast.connect(_on_spawn_knight)

	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager == null:
		_fail("US-016 independent: DungeonGenerationManager missing")
		return
	var response: Dictionary = manager.generate_dungeon_contract({
		"requestId": "us016-independent",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {
			"origin": {"x": 0, "y": 0},
			"size": {"x": 24, "y": 24}
		}
	}, 1)
	if not response.get("ok", false):
		_fail("US-016 independent: generation failed")
		return
	var pickups: Array = response.get("data", {}).get("itemPickups", [])
	var has_dew: bool = false
	var has_die: bool = false
	for pickup in pickups:
		var item_type: String = str(pickup.get("item_type", ""))
		if item_type == Planner.GREEN_DEW_PATH:
			has_dew = true
		if item_type == Planner.D6_PATH or item_type == Planner.D20_PATH:
			has_die = true
	if not has_dew or not has_die:
		_fail("US-016 independent: dungeon must contain Dew and a die")
		return

	DmUnlocks.reset_unlocks()
	DmManager.set_mana(0)
	DmHud.turn_on()
	if DmHud.spawn_knight.visible:
		_fail("US-016 independent: knight HUD must start hidden")
		return
	DmManager.set_mana(40)
	if DmManager.try_cast(Catalog.KNIGHTLING):
		_fail("US-016 independent: locked knightling must refuse")
		return

	DmManager.set_mana(0)
	var dew: ItemData = load("res://pickups/mtdew.tres") as ItemData
	var fantasy_before: int = DmManager.fantasy_level
	dew.use()
	if DmManager.current_mana != 25:
		_fail("US-016 independent: Dew must grant mana, got %d" % DmManager.current_mana)
		return
	if not bool(DmUnlocks.dm_unlocks.get(Catalog.KNIGHTLING, false)):
		_fail("US-016 independent: Dew must unlock knightling")
		return
	if not DmHud.spawn_knight.visible:
		_fail("US-016 independent: knight HUD must appear after Dew")
		return
	if DmManager.fantasy_level != fantasy_before:
		_fail("US-016 independent: Dew must not change Fantasy Level")
		return

	DmManager.set_mana(40)
	DmHud._on_knight_button_pressed()
	if _spawn_knight_count != 1:
		_fail("US-016 independent: unlocked knightling must spawn once")
		return
	if DmManager.current_mana != 0:
		_fail("US-016 independent: knightling must spend 40 mana")
		return
	if DmManager.fantasy_level != fantasy_before:
		_fail("US-016 independent: summon must not tax Fantasy Level")
		return

	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	add_child(level)
	await get_tree().process_frame
	level.apply_map_interior(Rect2i(0, 0, 16, 10), Rect2i(8, 2, 8, 6))
	await get_tree().process_frame
	var fantasy: Zone = load("res://zones/fantasy_zone.tscn").instantiate()
	add_child(fantasy)
	await get_tree().process_frame
	DmManager.fantasy_level = 0
	fantasy.clip_home_to_interior()
	var before_rect: Rect2i = fantasy.home_rect

	var d6: ItemData = load("res://pickups/d6.tres") as ItemData
	d6.use()
	if DmManager.fantasy_level != 6:
		_fail("US-016 independent: d6 must add 6 Fantasy Level")
		return
	fantasy.clip_home_to_interior()
	if fantasy.home_rect == before_rect:
		_fail("US-016 independent: Fantasy home rectangle must grow")
		return

	var pickup_scene: PackedScene = load("res://pickups/pickup.tscn")
	var die_pickup: ItemPickup = pickup_scene.instantiate() as ItemPickup
	add_child(die_pickup)
	die_pickup.item_data = d6
	die_pickup.can_be_picked_up = true
	await get_tree().process_frame
	var fl_before_skip: int = DmManager.fantasy_level
	var paper_pusher: Player = Player.new()
	die_pickup.on_body_entered(paper_pusher)
	if DmManager.fantasy_level != fl_before_skip or not die_pickup.visible:
		_fail("US-016 independent: Paper Pusher must not collect dice")
		return
	paper_pusher.free()

	print("US-016 independent test passed")
	get_tree().quit(0)

func _on_spawn_knight() -> void:
	_spawn_knight_count += 1

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
