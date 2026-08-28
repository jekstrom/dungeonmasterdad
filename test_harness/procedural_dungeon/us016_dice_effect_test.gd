extends Node

const IncreaseFantasy = preload("res://pickups/effects/increase_fantasy_level.gd")
const RestoreMana = preload("res://pickups/effects/restore_mana.gd")

func _ready() -> void:
	var d6: ItemData = load("res://pickups/d6.tres") as ItemData
	var d20: ItemData = load("res://pickups/d20.tres") as ItemData
	if d6 == null or d20 == null:
		_fail("US-016 T002: d6.tres and d20.tres must load as ItemData")
		return
	if d6.pickup_char != "dm_only" or d20.pickup_char != "dm_only":
		_fail("US-016 T002: dice must be dm_only")
		return
	if not d6.auto_use or not d20.auto_use:
		_fail("US-016 T002: dice must auto_use")
		return
	if d6.texture == null or d6.texture.resource_path != "res://pickups/d6/d6.png":
		_fail("US-016 T002: d6 must use pickups/d6/d6.png")
		return
	if d20.texture == null or d20.texture.resource_path != "res://pickups/d20/d20.png":
		_fail("US-016 T002: d20 must use pickups/d20/d20.png")
		return
	if not _has_fantasy_amount(d6, 6) or not _has_fantasy_amount(d20, 20):
		_fail("US-016 T002: d6 must grant +6 and d20 +20")
		return
	for effect in d6.effects:
		if effect is RestoreMana:
			_fail("US-016 T002: d6 must not restore mana")
			return
	for effect in d20.effects:
		if effect is RestoreMana:
			_fail("US-016 T002: d20 must not restore mana")
			return

	DmManager.set_mana(0)
	var fantasy_before: int = DmManager.fantasy_level
	var mana_before: int = DmManager.current_mana
	d6.use()
	if DmManager.fantasy_level != fantasy_before + 6:
		_fail("US-016 T002: d6 must add 6 Fantasy Level, got %d" % DmManager.fantasy_level)
		return
	if DmManager.current_mana != mana_before:
		_fail("US-016 T002: d6 must not change mana")
		return
	d20.use()
	if DmManager.fantasy_level != fantasy_before + 26:
		_fail("US-016 T002: d20 must add 20 Fantasy Level, got %d" % DmManager.fantasy_level)
		return
	if DmManager.current_mana != mana_before:
		_fail("US-016 T002: d20 must not change mana")
		return

	var pickup_scene: PackedScene = load("res://pickups/pickup.tscn")
	var pickup: ItemPickup = pickup_scene.instantiate() as ItemPickup
	add_child(pickup)
	pickup.item_data = d6
	pickup.can_be_picked_up = true
	await get_tree().process_frame
	var fl_before_skip: int = DmManager.fantasy_level
	var paper_pusher: Player = Player.new()
	pickup.on_body_entered(paper_pusher)
	if DmManager.fantasy_level != fl_before_skip:
		_fail("US-016 T002: Paper Pusher must not gain Fantasy Level from a die")
		return
	if not pickup.visible:
		_fail("US-016 T002: Paper Pusher must not consume the die")
		return
	paper_pusher.free()

	var dm: DM = DM.new()
	pickup.on_body_entered(dm)
	if DmManager.fantasy_level != fl_before_skip + 6:
		_fail("US-016 T002: DM die pickup must grant 6 Fantasy Level")
		return
	if pickup.visible:
		_fail("US-016 T002: DM die pickup must consume the die")
		return
	dm.free()

	var second: ItemPickup = pickup_scene.instantiate() as ItemPickup
	add_child(second)
	second.item_data = d20
	second.can_be_picked_up = true
	await get_tree().process_frame
	var fl_before_second: int = DmManager.fantasy_level
	var dm2: DM = DM.new()
	second.on_body_entered(dm2)
	dm2.free()
	if DmManager.fantasy_level != fl_before_second + 20:
		_fail("US-016 T002: sequential dice must both apply")
		return
	if second.visible:
		_fail("US-016 T002: second die must be consumed")
		return

	if ItemDatabase.get_item("res://pickups/d6.tres") == null:
		_fail("US-016 T002: ItemDatabase must load d6.tres")
		return
	if ItemDatabase.get_item("res://pickups/d20.tres") == null:
		_fail("US-016 T002: ItemDatabase must load d20.tres")
		return

	print("US-016 T002 dice effect test passed")
	get_tree().quit(0)

func _has_fantasy_amount(item: ItemData, amount: int) -> bool:
	for effect in item.effects:
		if effect is IncreaseFantasy and int(effect.fantasy_amount) == amount:
			return true
	return false

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
