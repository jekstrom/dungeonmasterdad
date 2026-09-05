extends Node


func _ready() -> void:
	if not _run_suite():
		return
	print("US-052 Dad Reflexes test passed")
	get_tree().quit(0)


func _run_suite() -> bool:
	DmUnlocks.reset_unlocks()
	if DmUnlocks.is_owned("dad_reflexes"):
		return _fail("US-052 AC1: dad_reflexes must start unowned")
	if not is_equal_approx(DmManager.dm_move_speed(), DmManager.DM_MOVE_SPEED):
		return _fail("US-052 AC1: unowned speed want %s got %s" % [DmManager.DM_MOVE_SPEED, DmManager.dm_move_speed()])
	if not is_equal_approx(DmManager.DM_MOVE_SPEED, 300.0):
		return _fail("US-052 AC1: baseline DM move speed must be 300")
	if not _assert_tooltip():
		return false
	if not _assert_no_dash():
		return false

	DmUnlocks.unlock("dad_reflexes")
	if not DmUnlocks.is_owned("dad_reflexes"):
		return _fail("US-052 FR-001: force-own dad_reflexes must stick")
	var want: float = DmManager.DM_MOVE_SPEED * DmManager.DAD_REFLEXES_SPEED_SCALE
	if not is_equal_approx(DmManager.DAD_REFLEXES_SPEED_SCALE, 1.5):
		return _fail("US-052 AC2: speed scale must be 1.5")
	if not is_equal_approx(DmManager.dm_move_speed(), want):
		return _fail("US-052 AC2: owned speed want %s got %s" % [want, DmManager.dm_move_speed()])
	if not _assert_no_dash():
		return false

	DmUnlocks.lock("dad_reflexes")
	if DmUnlocks.is_owned("dad_reflexes"):
		return _fail("US-052 AC3: lock must clear dad_reflexes")
	if not is_equal_approx(DmManager.dm_move_speed(), DmManager.DM_MOVE_SPEED):
		return _fail("US-052 AC3: lock must restore baseline speed")
	return true


func _assert_tooltip() -> bool:
	var tree_script: Script = load("res://gui/dm/skill_tree.gd") as Script
	if tree_script == null:
		return _fail("US-052 AC5: skill_tree.gd missing")
	for entry in tree_script.DAD_PASSIVES:
		if str(entry.get("id", "")) != "dad_reflexes":
			continue
		var effect: String = str(entry.get("effect", ""))
		if effect.find("dash") != -1:
			return _fail("US-052 AC5: tooltip must not say dash")
		if effect != "Increase DM movement speed 1.5×.":
			return _fail("US-052 AC5: tooltip want 1.5× speed copy got %s" % effect)
		return true
	return _fail("US-052 AC5: dad_reflexes missing from Dad passives")


func _assert_no_dash() -> bool:
	if InputMap.has_action("dash"):
		return _fail("US-052 FR-002: must not add a dash input")
	if InputMap.has_action("dm_dash"):
		return _fail("US-052 FR-002: must not add a dm_dash input")
	var dm_script: Script = load("res://dm/dm.gd") as Script
	if dm_script == null:
		return _fail("US-052: dm.gd missing")
	var src: String = dm_script.source_code
	if src.find("func dash") != -1 or src.find("is_action_pressed(\"dash\")") != -1:
		return _fail("US-052 FR-002: DM must not gain a dash ability")
	return true


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
