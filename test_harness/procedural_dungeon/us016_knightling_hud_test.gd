extends Node

const Catalog = preload("res://dm/dm_ability_catalog.gd")

var _spawn_knight_count: int = 0

func _ready() -> void:
	if not DmManager.spawn_knight_cast.is_connected(_on_spawn_knight):
		DmManager.spawn_knight_cast.connect(_on_spawn_knight)

	DmUnlocks.reset_unlocks()
	DmHud.turn_on()
	if DmHud.spawn_knight == null:
		_fail("US-016 T005: SpawnKnight control missing")
		return
	if DmHud.spawn_knight.visible:
		_fail("US-016 T005: knight control must be hidden while locked")
		return

	var fantasy_before: int = DmManager.fantasy_level
	DmManager.set_mana(40)
	DmHud._on_knight_button_pressed()
	if _spawn_knight_count != 0:
		_fail("US-016 T005: locked HUD press must not spawn")
		return
	if DmManager.current_mana != 40:
		_fail("US-016 T005: locked HUD press must not spend mana")
		return

	DmUnlocks.unlock(Catalog.KNIGHTLING)
	if not DmHud.spawn_knight.visible:
		_fail("US-016 T005: knight control must show after unlock")
		return

	DmHud._on_knight_button_pressed()
	if _spawn_knight_count != 1:
		_fail("US-016 T005: unlocked HUD with mana must spawn once, got %d" % _spawn_knight_count)
		return
	if DmManager.current_mana != 0:
		_fail("US-016 T005: knightling must cost 40")
		return
	if DmManager.fantasy_level != fantasy_before:
		_fail("US-016 T005: summon must not tax Fantasy Level")
		return

	DmManager.set_mana(0)
	DmHud._on_knight_button_pressed()
	if _spawn_knight_count != 1:
		_fail("US-016 T005: unlocked at 0 mana must not spawn")
		return

	print("US-016 T005 knightling HUD test passed")
	get_tree().quit(0)

func _on_spawn_knight() -> void:
	_spawn_knight_count += 1

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
