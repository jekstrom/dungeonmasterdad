extends Node

func _ready() -> void:
	var wood: ItemData = load("res://pickups/wood.tres") as ItemData
	var paper: ItemData = load("res://pickups/paper.tres") as ItemData
	var metal: ItemData = load("res://pickups/metal.tres") as ItemData
	var blank: ItemData = load("res://pickups/blank_form.tres") as ItemData
	if wood == null or paper == null or metal == null or blank == null:
		_fail("US-030 T001: required items must load")
		return
	if wood.inventory_row != "static" or metal.inventory_row != "static":
		_fail("US-030 T001: wood/metal must be static")
		return
	if paper.inventory_row != "active":
		_fail("US-030 T001: paper must be active")
		return
	if blank.inventory_row != "active":
		_fail("US-030 T001: blank form must be active")
		return
	if not blank.channel_use:
		_fail("US-030 T001: blank form must be channel_use")
		return
	print("US-030 T001 item row flags test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
