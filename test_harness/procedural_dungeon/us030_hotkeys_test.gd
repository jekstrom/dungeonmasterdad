extends Node

func _ready() -> void:
	if not InputMap.has_action("interact") or not InputMap.has_action("inv_slot_0"):
		_fail("US-030 T004: required actions missing")
		return
	if _action_uses_physical("interact", KEY_E):
		_fail("US-030 T004: interact must not be E")
		return
	if not _action_uses_physical("inv_slot_0", KEY_Q):
		_fail("US-030 T004: inv_slot_0 must be Q")
		return
	if not _action_uses_physical("inv_slot_1", KEY_E):
		_fail("US-030 T004: inv_slot_1 must be E")
		return
	if not _action_uses_physical("inv_slot_2", KEY_R):
		_fail("US-030 T004: inv_slot_2 must be R")
		return
	if not _action_uses_physical("inv_slot_3", KEY_T):
		_fail("US-030 T004: inv_slot_3 must be T")
		return
	if InputMap.has_action("fill_standard") or InputMap.has_action("fill_tax"):
		_fail("US-030 T004: fill_standard/fill_tax must be removed")
		return
	print("US-030 T004 hotkeys test passed")
	get_tree().quit(0)

func _action_uses_physical(action: String, code: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key: InputEventKey = event
			if key.physical_keycode == code or key.keycode == code:
				return true
	return false

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
