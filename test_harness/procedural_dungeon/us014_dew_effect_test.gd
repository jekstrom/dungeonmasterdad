extends Node

const RestoreMana = preload("res://pickups/effects/restore_mana.gd")

func _ready() -> void:
	var dew: ItemData = load("res://pickups/mtdew.tres") as ItemData
	if dew == null:
		_fail("US-014 T006: pickups/mtdew.tres must load as ItemData")
		return
	if dew.pickup_char != "dm_only":
		_fail("US-014 T006: green Dew must be dm_only")
		return
	if not dew.auto_use:
		_fail("US-014 T006: green Dew must auto_use")
		return
	if dew.texture == null or dew.texture.resource_path != "res://pickups/mtdew/mtdew.png":
		_fail("US-014 T006: green Dew must use pickups/mtdew/mtdew.png")
		return
	var restore: Resource = null
	for effect in dew.effects:
		if effect is RestoreMana:
			restore = effect
			break
	if restore == null:
		_fail("US-014 T006: green Dew must have ItemEffectRestoreMana")
		return
	if int(restore.mana_amount) != 25:
		_fail("US-014 T006: Dew restore amount must be 25")
		return

	var code_red: ItemData = load("res://pickups/code_red.tres") as ItemData
	if code_red == null:
		_fail("US-014 T006: code_red.tres missing")
		return
	for effect in code_red.effects:
		if effect is RestoreMana:
			_fail("US-014 T006: Code Red must not restore mana")
			return

	DmManager.set_mana(0)
	dew.use()
	if DmManager.current_mana != 25:
		_fail("US-014 T006: Dew use from 0 must grant 25 mana, got %d" % DmManager.current_mana)
		return

	DmManager.set_mana(90)
	dew.use()
	if DmManager.current_mana != 100:
		_fail("US-014 T006: Dew at 90 must clamp to 100, got %d" % DmManager.current_mana)
		return

	var mana_before_red: int = DmManager.current_mana
	code_red.use()
	if DmManager.current_mana != mana_before_red:
		_fail("US-014 T006: Code Red must not change mana")
		return
	DmUnlocks.dm_unlocks["fireball"] = false

	var pickup_scene: PackedScene = load("res://pickups/pickup.tscn")
	var pickup: ItemPickup = pickup_scene.instantiate() as ItemPickup
	add_child(pickup)
	pickup.item_data = dew
	pickup.can_be_picked_up = true
	await get_tree().process_frame

	DmManager.set_mana(0)
	var paper_pusher: Player = Player.new()
	pickup.on_body_entered(paper_pusher)
	if DmManager.current_mana != 0:
		_fail("US-014 T006: Paper Pusher must not gain DM mana from Dew")
		return
	if not pickup.visible:
		_fail("US-014 T006: Paper Pusher must not consume the Dew can")
		return
	paper_pusher.free()

	var dm: DM = DM.new()
	pickup.on_body_entered(dm)
	if DmManager.current_mana != 25:
		_fail("US-014 T006: DM pickup must grant 25 mana, got %d" % DmManager.current_mana)
		return
	if pickup.visible:
		_fail("US-014 T006: DM pickup must consume the Dew can")
		return
	dm.free()

	var overflow: ItemPickup = pickup_scene.instantiate() as ItemPickup
	add_child(overflow)
	overflow.item_data = dew
	overflow.can_be_picked_up = true
	await get_tree().process_frame
	DmManager.set_mana(90)
	var child_count_before: int = get_child_count()
	var overflow_dm: DM = DM.new()
	overflow.on_body_entered(overflow_dm)
	overflow_dm.free()
	if DmManager.current_mana != 100:
		_fail("US-014 T006: overflow Dew must clamp mana to 100")
		return
	if overflow.visible:
		_fail("US-014 T006: overflow Dew must still be consumed")
		return
	if get_child_count() > child_count_before:
		_fail("US-014 T006: overflow must not spawn a duplicate can")
		return

	var db_dew: ItemData = ItemDatabase.get_item("res://pickups/mtdew.tres")
	if db_dew == null:
		_fail("US-014 T006: ItemDatabase must load pickups/mtdew.tres")
		return

	DmManager.set_mana(0)
	print("US-014 T006 dew pickup test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
