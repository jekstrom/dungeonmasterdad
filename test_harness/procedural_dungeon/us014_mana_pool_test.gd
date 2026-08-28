extends Node

var _last_current: int = -1
var _last_max: int = -1
var _signal_count: int = 0

func _ready() -> void:
	if not DmManager.mana_changed.is_connected(_on_mana_changed):
		DmManager.mana_changed.connect(_on_mana_changed)

	if DmManager.current_mana != 0 or DmManager.max_mana != DmManager.DEFAULT_MAX_MANA:
		_fail("US-014 T001: new match mana must be 0/%d" % DmManager.DEFAULT_MAX_MANA)
		return

	var fantasy_before: int = DmManager.fantasy_level
	DmManager.add_mana(25)
	if DmManager.current_mana != 25 or DmManager.max_mana != 100:
		_fail("US-014 T001: add_mana(25) from 0 must yield 25/100")
		return
	if DmManager.fantasy_level != fantasy_before:
		_fail("US-014 T001: add_mana must not change fantasy_level")
		return
	if _last_current != 25 or _last_max != 100 or _signal_count < 1:
		_fail("US-014 T001: add_mana must emit mana_changed(25, 100)")
		return

	DmManager.set_mana(90)
	if DmManager.current_mana != 90:
		_fail("US-014 T001: set_mana(90) failed")
		return
	DmManager.add_mana(25)
	if DmManager.current_mana != 100:
		_fail("US-014 T001: add_mana(25) at 90 must clamp to 100, not %d" % DmManager.current_mana)
		return

	DmManager.set_mana(10)
	DmManager.add_mana(-50)
	if DmManager.current_mana != 0:
		_fail("US-014 T001: add_mana must clamp to 0, got %d" % DmManager.current_mana)
		return

	DmManager.set_mana(40)
	DmManager.current_mana = 7
	DmManager.max_mana = 50
	if DmManager.current_mana != 7:
		_fail("US-014 T001: local current_mana assign must stick until replicate")
		return
	DmManager.apply_replicated_mana(40, 100)
	if DmManager.current_mana != 40 or DmManager.max_mana != 100:
		_fail("US-014 T001: replicate must overwrite local current and max")
		return
	if _last_current != 40 or _last_max != 100:
		_fail("US-014 T001: apply_replicated_mana must emit mana_changed")
		return

	if Lobby.is_network_server():
		_fail("US-014 T001: test must run on OfflineMultiplayerPeer")
		return
	DmManager.set_mana(33)
	Lobby.host_started.emit("test")
	if DmManager.current_mana != 33:
		_fail("US-014 T001: OfflineMultiplayerPeer must not reset mana on host_started")
		return

	DmManager.set_mana(0)
	print("US-014 T001 mana pool test passed")
	get_tree().quit(0)

func _on_mana_changed(new_current: int, new_max: int) -> void:
	_last_current = new_current
	_last_max = new_max
	_signal_count += 1

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
