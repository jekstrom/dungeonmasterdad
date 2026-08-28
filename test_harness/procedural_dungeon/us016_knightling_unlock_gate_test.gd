extends Node

const Catalog = preload("res://dm/dm_ability_catalog.gd")

var _spawn_knight_count: int = 0

func _ready() -> void:
	if not DmManager.spawn_knight_cast.is_connected(_on_spawn_knight):
		DmManager.spawn_knight_cast.connect(_on_spawn_knight)

	if Catalog.unlock_id(Catalog.KNIGHTLING) != Catalog.UNLOCK_KNIGHTLING:
		_fail("US-016 T003: knightling unlock_id must be knightling")
		return
	if Catalog.cost(Catalog.KNIGHTLING) != 40:
		_fail("US-016 T003: knightling cost must stay 40")
		return
	if not Catalog.unlock_id(Catalog.GREMLIN).is_empty():
		_fail("US-016 T003: gremlin must stay ungated")
		return

	DmUnlocks.reset_unlocks()
	var fantasy_before: int = DmManager.fantasy_level
	DmManager.set_mana(40)
	if DmManager.try_cast(Catalog.KNIGHTLING):
		_fail("US-016 T003: locked knightling must refuse with mana 40")
		return
	if DmManager.current_mana != 40:
		_fail("US-016 T003: locked refuse must not spend mana")
		return
	if _spawn_knight_count != 0:
		_fail("US-016 T003: locked refuse must not spawn")
		return

	DmUnlocks.unlock(Catalog.KNIGHTLING)
	if not bool(DmUnlocks.dm_unlocks.get(Catalog.KNIGHTLING, false)):
		_fail("US-016 T003: unlock must set knightling true")
		return
	DmUnlocks.unlock(Catalog.KNIGHTLING)
	if not bool(DmUnlocks.dm_unlocks.get(Catalog.KNIGHTLING, false)):
		_fail("US-016 T003: second unlock must stay true")
		return

	if not DmManager.try_cast(Catalog.KNIGHTLING):
		_fail("US-016 T003: unlocked knightling must succeed at 40 mana")
		return
	if DmManager.current_mana != 0:
		_fail("US-016 T003: unlocked knightling must spend 40")
		return
	if DmManager.fantasy_level != fantasy_before:
		_fail("US-016 T003: try_cast must not tax Fantasy Level")
		return

	print("US-016 T003 knightling unlock gate test passed")
	get_tree().quit(0)

func _on_spawn_knight() -> void:
	_spawn_knight_count += 1

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
