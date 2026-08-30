extends Node

const WOOD_PATH := "res://pickups/wood.tres"
const PAPER_PATH := "res://pickups/paper.tres"

func _ready() -> void:
	var wood: ItemData = load(WOOD_PATH) as ItemData
	var paper: ItemData = load(PAPER_PATH) as ItemData
	if wood == null or paper == null:
		_fail("US-006 T001: wood.tres and paper.tres must load as ItemData")
		return
	if wood.pickup_char != "player_only" or paper.pickup_char != "player_only":
		_fail("US-006 T001: wood and paper must be player_only")
		return
	if wood.auto_use or paper.auto_use:
		_fail("US-006 T001: wood and paper must not auto_use")
		return
	if wood.name == paper.name:
		_fail("US-006 T001: wood and paper must have distinct names")
		return
	if wood.texture == null or wood.texture.resource_path != "res://pickups/wood/wood.png":
		_fail("US-006 T001: wood must use pickups/wood/wood.png")
		return
	if paper.texture == null or paper.texture.resource_path != "res://pickups/paper/paper.png":
		_fail("US-006 T001: paper must use pickups/paper/paper.png")
		return
	if str(paper.texture.resource_path).find("paper-sheet.png") != -1:
		_fail("US-006 T001: paper must not use sprites/paper-sheet.png")
		return
	if ItemDatabase.get_item(WOOD_PATH) == null or ItemDatabase.get_item(PAPER_PATH) == null:
		_fail("US-006 T001: ItemDatabase must load wood and paper")
		return

	PlayerManager.players_data.clear()
	PlayerManager.register_player(1, "Paper Pusher")
	if not PlayerManager.add_item_to_inventory(1, wood, 1):
		_fail("US-006 T001: Paper Pusher must receive wood")
		return
	if PlayerManager.get_item_count(1, WOOD_PATH) != 1:
		_fail("US-006 T001: wood stack must be 1")
		return
	if not PlayerManager.add_item_to_inventory(1, paper, 1):
		_fail("US-006 T001: Paper Pusher must receive paper as a separate stack")
		return
	if PlayerManager.get_item_count(1, PAPER_PATH) != 1:
		_fail("US-006 T001: paper stack must be 1")
		return
	if PlayerManager.get_item_count(1, WOOD_PATH) != 1:
		_fail("US-006 T001: wood must stay distinct from paper")
		return

	var pickup_scene: PackedScene = load("res://pickups/pickup.tscn")
	var pickup: ItemPickup = pickup_scene.instantiate() as ItemPickup
	add_child(pickup)
	pickup.item_data = wood
	pickup.can_be_picked_up = true
	await get_tree().process_frame
	var dm: DM = DM.new()
	pickup.on_body_entered(dm)
	dm.free()
	if not pickup.visible:
		_fail("US-006 T001: DM must not collect wood")
		return

	print("US-006 T001 wood paper items test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
