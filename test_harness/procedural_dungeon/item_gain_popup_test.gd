extends Node

const PAPER := "res://pickups/paper.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.register_player(1, "Paper Pusher")
	var body := Node2D.new()
	body.name = "1"
	body.add_to_group("players")
	add_child(body)

	var paper: ItemData = load(PAPER) as ItemData
	if paper == null or paper.texture == null:
		_fail("item gain popup: paper must load with a texture")
		return
	if not PlayerManager.add_item_to_inventory(1, paper, 1):
		_fail("item gain popup: add paper must succeed")
		return
	await get_tree().process_frame
	var popup := _find_popup(body)
	if popup == null:
		_fail("item gain popup: adding an item must spawn a popup above the player")
		return
	if popup.texture != paper.texture:
		_fail("item gain popup: popup must use the added item's icon")
		return
	if popup.position.y > -1.0:
		_fail("item gain popup: icon must start above the player")
		return
	await get_tree().create_timer(0.55).timeout
	if is_instance_valid(popup):
		_fail("item gain popup: icon must disappear after 0.5s")
		return
	print("item gain popup test passed")
	get_tree().quit(0)

func _find_popup(body: Node) -> ItemGainPopup:
	for child in body.get_children():
		if child is ItemGainPopup:
			return child as ItemGainPopup
	return null

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
