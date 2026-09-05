extends Node

const WOOD := "res://pickups/wood.tres"
const METAL := "res://pickups/metal.tres"
const PAPER := "res://pickups/paper.tres"
const BLANK := "res://pickups/blank_form.tres"
const FILLED := "res://pickups/filled_form.tres"
const TAX := "res://pickups/tax_form.tres"
const DEW := "res://pickups/mtdew.tres"
const RADIUS := 100.0


func _ready() -> void:
	if not await _run_suite():
		return
	print("US-050 Everything Burns test passed")
	get_tree().quit(0)


func _run_suite() -> bool:
	DmUnlocks.reset_unlocks()
	DmManager.clear_fireball_cooldown()
	if DmUnlocks.is_owned("everything_burns"):
		return _fail("US-050 AC1: everything_burns must start unowned")
	if not ItemData.is_world_resource_path(WOOD):
		return _fail("US-050: wood must be a world resource")
	if not ItemData.is_world_resource_path(METAL):
		return _fail("US-050: metal must be a world resource")
	if not ItemData.is_world_resource_path(PAPER):
		return _fail("US-050: paper must be a world resource")
	if not ItemData.is_world_resource_path(BLANK):
		return _fail("US-050: blank form must be a world resource")
	if not ItemData.is_world_resource_path(FILLED):
		return _fail("US-050: filled form must be a world resource")
	if not ItemData.is_world_resource_path(TAX):
		return _fail("US-050: tax form must be a world resource")
	if ItemData.is_world_resource_path(DEW):
		return _fail("US-050: dew must not be a world resource")
	if not _assert_tooltip():
		return false
	if not await _assert_unowned_baseline():
		return false
	DmUnlocks.unlock("everything_burns")
	if not DmUnlocks.is_owned("everything_burns"):
		return _fail("US-050 FR-001: force-own everything_burns must stick")
	if not await _assert_owned_burns():
		return false
	if not await _assert_inventory_untouched():
		return false
	if not await _assert_non_fire_skipped():
		return false
	DmUnlocks.lock("everything_burns")
	if DmUnlocks.is_owned("everything_burns"):
		return _fail("US-050 AC3: lock must clear everything_burns")
	if not await _assert_unowned_baseline():
		return false
	return true


func _assert_tooltip() -> bool:
	var tree_script: Script = load("res://gui/dm/skill_tree.gd") as Script
	if tree_script == null:
		return _fail("US-050 AC5: skill_tree.gd missing")
	var passives: Array = tree_script.DAD_PASSIVES
	for entry in passives:
		if str(entry.get("id", "")) != "everything_burns":
			continue
		if str(entry.get("effect", "")) != "Fireball now destroys resources.":
			return _fail("US-050 AC5: tooltip must stay US-035 copy")
		return true
	return _fail("US-050 AC5: everything_burns missing from Dad passives")


func _assert_unowned_baseline() -> bool:
	var wood: ItemPickup = await _spawn_pickup(WOOD, Vector2(16, 16))
	var dew: ItemPickup = await _spawn_pickup(DEW, Vector2(16, 16))
	var burned: int = DmManager.apply_everything_burns(_fire_data(Vector2(16, 16)))
	if burned != 0:
		return _fail("US-050 AC1: unowned fireball must not burn resources, got %d" % burned)
	if not wood.visible:
		return _fail("US-050 AC1: unowned must leave wood")
	if not dew.visible:
		return _fail("US-050 AC1: unowned must leave dew")
	wood.queue_free()
	dew.queue_free()
	await get_tree().process_frame
	return true


func _assert_owned_burns() -> bool:
	var wood: ItemPickup = await _spawn_pickup(WOOD, Vector2(32, 32))
	var paper: ItemPickup = await _spawn_pickup(PAPER, Vector2(40, 32))
	var dew: ItemPickup = await _spawn_pickup(DEW, Vector2(32, 32))
	var far: ItemPickup = await _spawn_pickup(WOOD, Vector2(800, 32))
	var burned: int = DmManager.apply_everything_burns(_fire_data(Vector2(32, 32)))
	if burned != 2:
		return _fail("US-050 AC2: owned fireball must burn in-radius resources, got %d" % burned)
	if wood.visible:
		return _fail("US-050 AC2: in-radius wood must be destroyed")
	if paper.visible:
		return _fail("US-050 AC2: in-radius paper must be destroyed")
	if not dew.visible:
		return _fail("US-050 AC2: dew must survive Everything Burns")
	if not far.visible:
		return _fail("US-050 AC2: out-of-radius wood must survive")
	if not _has_burn_vfx():
		return _fail("US-050 T004: burn VFX must spawn on destroyed pickups")
	dew.queue_free()
	far.queue_free()
	await get_tree().process_frame
	return true


func _assert_inventory_untouched() -> bool:
	PlayerManager.players_data.clear()
	PlayerManager.register_player(1, "Paper Pusher")
	var wood_data: ItemData = load(WOOD) as ItemData
	if not PlayerManager.add_item_to_inventory(1, wood_data, 2):
		return _fail("US-050: failed to seed inventory wood")
	var world: ItemPickup = await _spawn_pickup(WOOD, Vector2(64, 64))
	var burned: int = DmManager.apply_everything_burns(_fire_data(Vector2(64, 64)))
	if burned != 1:
		return _fail("US-050: inventory case must burn world wood, got %d" % burned)
	if PlayerManager.get_item_count(1, WOOD) != 2:
		return _fail("US-050 FR-002: must not wipe player inventory")
	if world.visible:
		return _fail("US-050 FR-002: world wood must still burn")
	return true


func _assert_non_fire_skipped() -> bool:
	var wood: ItemPickup = await _spawn_pickup(WOOD, Vector2(8, 8))
	var data := {
		"type": "ice",
		"damage": 5,
		"radius": RADIUS,
		"position": Vector2(8, 8),
	}
	var burned: int = DmManager.apply_everything_burns(data)
	if burned != 0:
		return _fail("US-050: non-fire explosion must not burn resources")
	if not wood.visible:
		return _fail("US-050: non-fire must leave wood")
	var level: Node = Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	add_child(level)
	await get_tree().process_frame
	level.handle_explosion(_fire_data(Vector2(8, 8)))
	if wood.visible:
		return _fail("US-050 AC4: handle_explosion must burn when owned")
	level.queue_free()
	await get_tree().process_frame
	return true


func _spawn_pickup(item_path: String, world_pos: Vector2) -> ItemPickup:
	var pickup: ItemPickup = load("res://pickups/pickup.tscn").instantiate() as ItemPickup
	pickup.item_data = load(item_path) as ItemData
	add_child(pickup)
	pickup.global_position = world_pos
	pickup.visible = true
	await get_tree().process_frame
	return pickup


func _fire_data(origin: Vector2) -> Dictionary:
	return {
		"type": "fire",
		"damage": 5,
		"radius": RADIUS,
		"position": origin,
	}


func _has_burn_vfx() -> bool:
	var packed: PackedScene = load("res://spells/fireball/resource_burn_vfx.tscn") as PackedScene
	if packed == null:
		return false
	var probe: Node = packed.instantiate()
	var script: Script = probe.get_script() as Script
	probe.queue_free()
	for child in get_children():
		if child.get_script() == script:
			return true
	var tree := get_tree()
	if tree and tree.current_scene:
		for child in tree.current_scene.get_children():
			if child.get_script() == script:
				return true
	return false


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
