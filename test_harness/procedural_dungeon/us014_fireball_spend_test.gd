extends Node

const Catalog = preload("res://dm/dm_ability_catalog.gd")

var _spell_cast_count: int = 0
var _start_cast_count: int = 0

func _ready() -> void:
	if not SignalBus.spell_cast.is_connected(_on_spell_cast):
		SignalBus.spell_cast.connect(_on_spell_cast)
	if not SignalBus.start_spell_cast.is_connected(_on_start_cast):
		SignalBus.start_spell_cast.connect(_on_start_cast)

	DmUnlocks.dm_unlocks[Catalog.FIREBALL] = false
	DmManager.set_mana(25)
	var fantasy_before: int = DmManager.fantasy_level
	DmHud._on_fireball_button_pressed()
	if _start_cast_count != 0:
		_fail("US-014 T005: locked fireball HUD must not start targeting")
		return
	if _spell_cast_count != 0 or DmManager.current_mana != 25:
		_fail("US-014 T005: locked HUD press must not launch or spend")
		return

	DmUnlocks.dm_unlocks[Catalog.FIREBALL] = true
	DmHud._on_fireball_button_pressed()
	if _start_cast_count != 1:
		_fail("US-014 T005: unlocked fireball HUD must start targeting")
		return
	if DmManager.current_mana != 25 or DmManager.fantasy_level != fantasy_before:
		_fail("US-014 T005: targeting start must not spend mana or grant Fantasy Level")
		return
	if _spell_cast_count != 0:
		_fail("US-014 T005: targeting start must not emit spell_cast")
		return

	var spell_data := {
		"shooter_id": 1,
		"position": Vector2.ZERO,
		"target": Vector2(64, 64),
		"radius_bonus": 0,
		"base_damage_bonus": 0,
		"speed_bonus": 0,
	}

	DmUnlocks.dm_unlocks[Catalog.FIREBALL] = false
	DmManager.set_mana(25)
	if DmManager.launch_fireball(spell_data):
		_fail("US-014 T005: locked fireball confirm must fail")
		return
	if DmManager.current_mana != 25 or _spell_cast_count != 0:
		_fail("US-014 T005: locked confirm must not spawn or spend")
		return

	DmUnlocks.dm_unlocks[Catalog.FIREBALL] = true
	DmManager.set_mana(0)
	if DmManager.launch_fireball(spell_data):
		_fail("US-014 T005: fireball at 0 mana must fail")
		return
	if DmManager.current_mana != 0 or _spell_cast_count != 0:
		_fail("US-014 T005: 0 mana confirm must not spawn")
		return

	DmManager.set_mana(10)
	if DmManager.launch_fireball(spell_data):
		_fail("US-014 T005: fireball at 10 mana must fail")
		return
	if DmManager.current_mana != 10 or _spell_cast_count != 0:
		_fail("US-014 T005: short mana confirm must leave mana and world unchanged")
		return

	DmManager.set_mana(25)
	if not DmManager.launch_fireball(spell_data):
		_fail("US-014 T005: fireball at 25 mana must launch")
		return
	if DmManager.current_mana != 10:
		_fail("US-014 T005: successful fireball must cost 15, mana is %d" % DmManager.current_mana)
		return
	if _spell_cast_count != 1:
		_fail("US-014 T005: successful fireball must emit one spell_cast, got %d" % _spell_cast_count)
		return
	if DmManager.fantasy_level != fantasy_before + 15:
		_fail("US-014 T005: leftover Fantasy Level grant must apply only on successful launch")
		return

	DmUnlocks.dm_unlocks[Catalog.FIREBALL] = false
	DmManager.set_mana(0)
	print("US-014 T005 fireball spend test passed")
	get_tree().quit(0)

func _on_spell_cast(_spell_id: String, _spell_data: Dictionary) -> void:
	_spell_cast_count += 1

func _on_start_cast(_spell_id: String) -> void:
	_start_cast_count += 1

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
