extends Node

const WOOD := "res://pickups/wood.tres"
const METAL := "res://pickups/metal.tres"
const COAL := "res://pickups/coal.tres"
const STONE := "res://pickups/stone.tres"
const BLANK := "res://pickups/blank_form.tres"

var _drops: Array = []


func _ready() -> void:
	if not SignalBus.on_item_drop.is_connected(_on_item_drop):
		SignalBus.on_item_drop.connect(_on_item_drop)
	if not await _run_suite():
		return
	print("US-051 Thermostat Lock test passed")
	get_tree().quit(0)


func _run_suite() -> bool:
	DmUnlocks.reset_unlocks()
	PlayerManager.players_data.clear()
	PlayerManager.register_player(2, "Paper Pusher")
	if DmUnlocks.is_owned("thermostat_lock"):
		return _fail("US-051 AC1: thermostat_lock must start unowned")
	if PlayerManager.thermostat_lock_applies(2):
		return _fail("US-051 AC1: unowned must not trim PP slots")
	if PlayerManager.static_slot_count_for(2) != PlayerManager.STATIC_SLOT_COUNT:
		return _fail("US-051 AC1: unowned static slots want %d" % PlayerManager.STATIC_SLOT_COUNT)
	if not _fill_static(2, [WOOD, METAL, COAL, STONE]):
		return _fail("US-051 AC1: unowned PP must keep 4 static slots")
	if not PlayerManager.is_slot_usable(2, 7):
		return _fail("US-051 AC1: unowned last static slot must be usable")
	if not _assert_tooltip():
		return false

	_drops.clear()
	DmUnlocks.unlock("thermostat_lock")
	if not DmUnlocks.is_owned("thermostat_lock"):
		return _fail("US-051 FR-001: force-own thermostat_lock must stick")
	if not PlayerManager.thermostat_lock_applies(2):
		return _fail("US-051 AC2: owned must apply to Paper Pushers")
	if PlayerManager.static_slot_count_for(2) != 3:
		return _fail("US-051 AC2: owned static slots want 3 got %d" % PlayerManager.static_slot_count_for(2))
	if PlayerManager.is_slot_usable(2, 7):
		return _fail("US-051 AC2: last static slot must be disabled")
	if PlayerManager.is_slot_usable(2, 6) == false:
		return _fail("US-051 AC2: third static slot must remain")
	var slots: Array = PlayerManager.get_slots(2)
	if str(slots[7].get("path", "")) != "":
		return _fail("US-051 AC2: trimmed slot must be empty")
	if PlayerManager.get_item_count(2, STONE) != 0:
		return _fail("US-051 AC2: overflow item must leave the bag")
	if _drops.is_empty() or str(_drops[0].get("item_type", "")) != STONE:
		return _fail("US-051 AC2: overflow must drop as world pickup")
	if PlayerManager.add_item_to_inventory(2, load(STONE) as ItemData, 1):
		return _fail("US-051 AC2: fourth unique static must fail while owned")
	if not PlayerManager.add_item_to_inventory(2, load(BLANK) as ItemData, 1):
		return _fail("US-051 AC2: active row must stay 4 slots")

	if not await _assert_hud_hides_trimmed_slot():
		return false
	if not await _assert_dm_unaffected():
		return false

	DmUnlocks.lock("thermostat_lock")
	if DmUnlocks.is_owned("thermostat_lock"):
		return _fail("US-051 AC3: lock must clear thermostat_lock")
	if PlayerManager.thermostat_lock_applies(2):
		return _fail("US-051 AC3: lock must restore PP capacity")
	if not PlayerManager.is_slot_usable(2, 7):
		return _fail("US-051 AC3: last static slot must return")
	if not PlayerManager.add_item_to_inventory(2, load(STONE) as ItemData, 1):
		return _fail("US-051 AC3: fourth static must fit after lock")
	return true


func _fill_static(player_id: int, paths: Array) -> bool:
	for path in paths:
		if not PlayerManager.add_item_to_inventory(player_id, load(path) as ItemData, 1):
			return false
	return true


func _assert_tooltip() -> bool:
	var tree_script: Script = load("res://gui/dm/skill_tree.gd") as Script
	if tree_script == null:
		return _fail("US-051 AC5: skill_tree.gd missing")
	for entry in tree_script.DAD_PASSIVES:
		if str(entry.get("id", "")) != "thermostat_lock":
			continue
		if str(entry.get("effect", "")) != "Paper Pushers lose one inventory slot.":
			return _fail("US-051 AC5: tooltip must stay US-035 copy")
		return true
	return _fail("US-051 AC5: thermostat_lock missing from Dad passives")


func _assert_hud_hides_trimmed_slot() -> bool:
	var root: Control = load("res://player/inventory/inventory_ui.tscn").instantiate() as Control
	add_child(root)
	await get_tree().process_frame
	var grid: GridContainer = root.get_node_or_null("GridContainer") as GridContainer
	if grid == null:
		grid = root as GridContainer
	if grid == null:
		return _fail("US-051: inventory grid missing")
	grid.update_inventory()
	await get_tree().process_frame
	if grid.get_child_count() != 8:
		return _fail("US-051: HUD still has 8 cell nodes, got %d" % grid.get_child_count())
	var last: Control = grid.get_child(7) as Control
	if last == null or not last.visible:
		return _fail("US-051 AC4: trimmed static cell must stay on the HUD")
	if last.has_method("is_locked") and not bool(last.call("is_locked")):
		return _fail("US-051 AC4: trimmed static cell must be locked")
	var icon: TextureRect = last.get_node_or_null("LockIcon") as TextureRect
	if icon == null or not icon.visible or icon.texture == null:
		return _fail("US-051 AC4: locked cell must show the thermostat icon")
	if str(icon.texture.resource_path).find("icon_thermostat_lock") == -1:
		return _fail("US-051 AC4: lock icon must be the thermostat art")
	root.queue_free()
	await get_tree().process_frame
	return true


func _assert_dm_unaffected() -> bool:
	var dummy := Node2D.new()
	dummy.name = "1"
	dummy.add_to_group("dm")
	add_child(dummy)
	await get_tree().process_frame
	PlayerManager.register_player(1, "Dungeon Master")
	if PlayerManager.thermostat_lock_applies(1):
		dummy.queue_free()
		return _fail("US-051: Thermostat Lock must not trim the DM")
	if not _fill_static(1, [WOOD, METAL, COAL, STONE]):
		dummy.queue_free()
		return _fail("US-051: DM must keep 4 static slots while owned")
	dummy.queue_free()
	await get_tree().process_frame
	return true


func _on_item_drop(data: Dictionary) -> void:
	_drops.append(data)


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
