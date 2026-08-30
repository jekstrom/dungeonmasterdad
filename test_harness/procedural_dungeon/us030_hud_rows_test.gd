extends Node

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.register_player(1, "Paper Pusher")
	PlayerManager.add_item_to_inventory(1, load("res://pickups/blank_form.tres") as ItemData, 1)
	PlayerManager.add_item_to_inventory(1, load("res://pickups/wood.tres") as ItemData, 1)
	var root: Control = load("res://player/inventory/inventory_ui.tscn").instantiate() as Control
	add_child(root)
	await get_tree().process_frame
	var grid: GridContainer = root.get_node_or_null("GridContainer") as GridContainer
	if grid == null:
		_fail("US-030 T003: GridContainer missing")
		return
	grid.update_inventory()
	await get_tree().process_frame
	if grid.get_child_count() != 8:
		_fail("US-030 T003: expected 8 cells, got %d" % grid.get_child_count())
		return
	var a0: InventorySlotUi = grid.get_child(0) as InventorySlotUi
	var s0: InventorySlotUi = grid.get_child(4) as InventorySlotUi
	if a0 == null or s0 == null:
		_fail("US-030 T003: slot scripts missing")
		return
	if a0.hotkey.text != "Q":
		_fail("US-030 T003: first active hotkey must be Q, got '%s'" % a0.hotkey.text)
		return
	if grid.get_child(1).hotkey.text != "E":
		_fail("US-030 T003: second active hotkey must be E")
		return
	if grid.get_child(2).hotkey.text != "R" or grid.get_child(3).hotkey.text != "T":
		_fail("US-030 T003: third/fourth hotkeys must be R/T")
		return
	if a0.bg.color.is_equal_approx(s0.bg.color):
		_fail("US-030 T003: active and static backgrounds must differ")
		return
	print("US-030 T003 hud rows test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
