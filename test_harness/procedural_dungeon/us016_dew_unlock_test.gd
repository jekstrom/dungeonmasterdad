extends Node

const UnlockKnightling = preload("res://pickups/effects/unlock_knightling.gd")
const RestoreMana = preload("res://pickups/effects/restore_mana.gd")
const Catalog = preload("res://dm/dm_ability_catalog.gd")

func _ready() -> void:
	var dew: ItemData = load("res://pickups/mtdew.tres") as ItemData
	if dew == null:
		_fail("US-016 T004: mtdew.tres must load")
		return
	var has_mana: bool = false
	var has_unlock: bool = false
	for effect in dew.effects:
		if effect is RestoreMana:
			has_mana = true
		if effect is UnlockKnightling:
			has_unlock = true
	if not has_mana or not has_unlock:
		_fail("US-016 T004: Dew must restore mana and unlock knightling")
		return

	DmUnlocks.reset_unlocks()
	DmManager.set_mana(0)
	var fantasy_before: int = DmManager.fantasy_level
	dew.use()
	if DmManager.current_mana != 25:
		_fail("US-016 T004: first Dew must grant 25 mana, got %d" % DmManager.current_mana)
		return
	if not bool(DmUnlocks.dm_unlocks.get(Catalog.KNIGHTLING, false)):
		_fail("US-016 T004: first Dew must unlock knightling")
		return
	if DmManager.fantasy_level != fantasy_before:
		_fail("US-016 T004: Dew must not change Fantasy Level")
		return

	dew.use()
	if DmManager.current_mana != 50:
		_fail("US-016 T004: second Dew must still grant mana, got %d" % DmManager.current_mana)
		return
	if not bool(DmUnlocks.dm_unlocks.get(Catalog.KNIGHTLING, false)):
		_fail("US-016 T004: second Dew must leave knightling unlocked")
		return

	DmUnlocks.reset_unlocks()
	var code_red: ItemData = load("res://pickups/code_red.tres") as ItemData
	if code_red == null:
		_fail("US-016 T004: code_red.tres missing")
		return
	code_red.use()
	if bool(DmUnlocks.dm_unlocks.get(Catalog.KNIGHTLING, false)):
		_fail("US-016 T004: Code Red must not unlock knightling")
		return

	var pickup_scene: PackedScene = load("res://pickups/pickup.tscn")
	var pickup: ItemPickup = pickup_scene.instantiate() as ItemPickup
	add_child(pickup)
	pickup.item_data = dew
	pickup.can_be_picked_up = true
	await get_tree().process_frame
	DmUnlocks.reset_unlocks()
	DmManager.set_mana(0)
	var paper_pusher: Player = Player.new()
	pickup.on_body_entered(paper_pusher)
	if bool(DmUnlocks.dm_unlocks.get(Catalog.KNIGHTLING, false)):
		_fail("US-016 T004: Paper Pusher must not unlock knightling")
		return
	if not pickup.visible:
		_fail("US-016 T004: Paper Pusher must not consume Dew")
		return
	paper_pusher.free()

	print("US-016 T004 dew unlock test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
