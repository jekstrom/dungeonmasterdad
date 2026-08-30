extends Node

const METAL := "res://pickups/metal.tres"

func _ready() -> void:
	var metal: ItemData = load(METAL) as ItemData
	if metal == null:
		_fail("US-007 T001: metal.tres must load as ItemData")
		return
	if metal.pickup_char != "player_only":
		_fail("US-007 T001: metal must be player_only")
		return
	if metal.auto_use:
		_fail("US-007 T001: metal must not auto_use")
		return
	if ItemDatabase.get_item(METAL) == null:
		_fail("US-007 T001: ItemDatabase must load metal.tres")
		return
	var smoke: BuildingData = load("res://buildings/buildables/SmokeFactory.tres") as BuildingData
	var paper: BuildingData = load("res://buildings/buildables/PaperFactory.tres") as BuildingData
	if smoke == null or paper == null:
		_fail("US-007 T001: factory BuildingData missing")
		return
	if smoke.cost_item != METAL or paper.cost_item != METAL:
		_fail("US-007 T001: factories must cost metal.tres")
		return
	if smoke.cost_qty != 3 or paper.cost_qty != 3:
		_fail("US-007 T001: factory cost_qty must be 3")
		return
	PlayerManager.players_data.clear()
	PlayerManager.register_player(1, "Paper Pusher")
	if not PlayerManager.add_item_to_inventory(1, metal, 2):
		_fail("US-007 T001: Paper Pusher must receive metal")
		return
	if PlayerManager.get_item_count(1, METAL) != 2:
		_fail("US-007 T001: metal stack must be 2")
		return
	var pickup: ItemPickup = load("res://pickups/pickup.tscn").instantiate() as ItemPickup
	add_child(pickup)
	pickup.item_data = metal
	pickup.can_be_picked_up = true
	await get_tree().process_frame
	var dm: DM = DM.new()
	pickup.on_body_entered(dm)
	dm.free()
	if not pickup.visible:
		_fail("US-007 T001: DM must not collect metal")
		return
	print("US-007 T001 iron item test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
