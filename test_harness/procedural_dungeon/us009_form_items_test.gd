extends Node

const BLANK := "res://pickups/blank_form.tres"
const FILLED := "res://pickups/filled_form.tres"
const TAX := "res://pickups/tax_form.tres"

func _ready() -> void:
	for path in [BLANK, FILLED, TAX]:
		var item: ItemData = load(path) as ItemData
		if item == null:
			_fail("US-009 T001: %s must load as ItemData" % path)
			return
		if item.pickup_char != "player_only":
			_fail("US-009 T001: %s must be player_only" % path)
			return
		if item.auto_use:
			_fail("US-009 T001: %s must not auto_use" % path)
			return
		if ItemDatabase.get_item(path) == null:
			_fail("US-009 T001: ItemDatabase must load %s" % path)
			return
	PlayerManager.players_data.clear()
	PlayerManager.register_player(1, "Paper Pusher")
	var blank: ItemData = load(BLANK) as ItemData
	if not PlayerManager.add_item_to_inventory(1, blank, 1):
		_fail("US-009 T001: Paper Pusher must receive a blank form")
		return
	if PlayerManager.get_item_count(1, BLANK) != 1:
		_fail("US-009 T001: blank form stack must be 1")
		return
	var pickup: ItemPickup = load("res://pickups/pickup.tscn").instantiate() as ItemPickup
	add_child(pickup)
	pickup.item_data = blank
	pickup.can_be_picked_up = true
	await get_tree().process_frame
	var dm: DM = DM.new()
	pickup.on_body_entered(dm)
	dm.free()
	if not pickup.visible:
		_fail("US-009 T001: DM must not collect blank forms")
		return
	print("US-009 T001 form items test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
