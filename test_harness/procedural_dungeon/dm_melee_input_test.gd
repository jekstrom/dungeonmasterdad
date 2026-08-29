extends Node

const DM_SCENE := preload("res://dm/dm.tscn")


func _ready() -> void:
	if not await _run():
		return
	print("DM melee input test passed")
	get_tree().quit(0)


func _run() -> bool:
	var dm: DM = DM_SCENE.instantiate() as DM
	add_child(dm)
	await get_tree().process_frame
	var lmb := InputEventMouseButton.new()
	lmb.button_index = MOUSE_BUTTON_LEFT
	lmb.pressed = true
	if not dm.wants_melee_attack(lmb):
		_fail("DM mouse1 must start melee")
		return false
	dm.current_targeting = Node2D.new()
	if dm.wants_melee_attack(lmb):
		_fail("DM mouse1 must not melee while a spell reticle is up")
		return false
	dm.current_targeting.queue_free()
	dm.current_targeting = null
	dm.set("_dead", true)
	if dm.wants_melee_attack(lmb):
		_fail("downed DM must not melee")
		return false
	dm.queue_free()
	await get_tree().process_frame
	return true


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
