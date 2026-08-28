extends Node

const Catalog = preload("res://dm/dm_ability_catalog.gd")

func _ready() -> void:
	DmUnlocks.reset_unlocks()
	if bool(DmUnlocks.dm_unlocks.get(Catalog.KNIGHTLING, false)):
		_fail("US-016 T007: reset must leave knightling locked")
		return

	DmUnlocks.dm_unlocks[Catalog.KNIGHTLING] = true
	var payload: Dictionary = DmUnlocks.snapshot()
	DmUnlocks.dm_unlocks[Catalog.KNIGHTLING] = false
	DmUnlocks.apply_replicated_unlocks(payload)
	if not bool(DmUnlocks.dm_unlocks.get(Catalog.KNIGHTLING, false)):
		_fail("US-016 T007: replicated payload must restore knightling unlock")
		return

	DmUnlocks.dm_unlocks[Catalog.KNIGHTLING] = true
	DmUnlocks.apply_replicated_unlocks({Catalog.KNIGHTLING: false})
	if bool(DmUnlocks.dm_unlocks.get(Catalog.KNIGHTLING, false)):
		_fail("US-016 T007: host replicate must overwrite a local unlock")
		return

	DmUnlocks.unlock(Catalog.KNIGHTLING)
	if not bool(DmUnlocks.dm_unlocks.get(Catalog.KNIGHTLING, false)):
		_fail("US-016 T007: unlock must set knightling")
		return
	DmUnlocks.reset_unlocks()
	if bool(DmUnlocks.dm_unlocks.get(Catalog.KNIGHTLING, false)):
		_fail("US-016 T007: match reset must clear knightling")
		return
	if bool(DmUnlocks.dm_unlocks.get(Catalog.FIREBALL, false)):
		_fail("US-016 T007: match reset must clear fireball")
		return

	var pickup_scene: PackedScene = load("res://pickups/pickup.tscn")
	var dew: ItemData = load("res://pickups/mtdew.tres") as ItemData
	var pickup: ItemPickup = pickup_scene.instantiate() as ItemPickup
	add_child(pickup)
	pickup.item_data = dew
	pickup.can_be_picked_up = true
	await get_tree().process_frame
	DmUnlocks.reset_unlocks()
	DmManager.set_mana(0)
	var dm: DM = DM.new()
	pickup.on_body_entered(dm)
	if not bool(DmUnlocks.dm_unlocks.get(Catalog.KNIGHTLING, false)):
		_fail("US-016 T007: Dew pickup must unlock once")
		return
	if pickup.visible:
		_fail("US-016 T007: Dew must be consumed once")
		return
	var mana_after: int = DmManager.current_mana
	var second_dm: DM = DM.new()
	pickup.on_body_entered(second_dm)
	if DmManager.current_mana != mana_after:
		_fail("US-016 T007: consumed Dew must not apply twice")
		return
	dm.free()
	second_dm.free()

	print("US-016 T007 unlock replication test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
