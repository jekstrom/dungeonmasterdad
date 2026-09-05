extends Node

const Catalog = preload("res://dm/dm_ability_catalog.gd")


func _ready() -> void:
	if not _run_suite():
		return
	print("US-049 Full Cord test passed")
	get_tree().quit(0)


func _run_suite() -> bool:
	DmUnlocks.reset_unlocks()
	DmManager.clear_fireball_cooldown()
	if DmUnlocks.is_owned("full_cord"):
		return _fail("US-049 AC1: full_cord must start unowned")
	if DmManager.ability_cost(Catalog.FIREBALL) != Catalog.COST_FIREBALL:
		return _fail("US-049 AC1: unowned fireball cost want %d got %d" % [Catalog.COST_FIREBALL, DmManager.ability_cost(Catalog.FIREBALL)])
	if not is_equal_approx(DmManager.fireball_cooldown(), DmManager.FIREBALL_COOLDOWN):
		return _fail("US-049 AC1: unowned cooldown want %s got %s" % [DmManager.FIREBALL_COOLDOWN, DmManager.fireball_cooldown()])
	if not _assert_cast_cost(Catalog.COST_FIREBALL):
		return false
	if DmManager.launch_fireball(_spell_data()):
		return _fail("US-049 AC1: fireball on cooldown must fail")
	DmManager.clear_fireball_cooldown()

	DmUnlocks.unlock("full_cord")
	if not DmUnlocks.is_owned("full_cord"):
		return _fail("US-049 FR-001: force-own full_cord must stick")
	var want_cost: int = maxi(1, Catalog.COST_FIREBALL - DmManager.FIREBALL_CORD_COST_DELTA)
	if DmManager.ability_cost(Catalog.FIREBALL) != want_cost:
		return _fail("US-049 AC2: owned fireball cost want %d got %d" % [want_cost, DmManager.ability_cost(Catalog.FIREBALL)])
	var want_cd: float = DmManager.FIREBALL_CORD_COOLDOWN
	if not is_equal_approx(DmManager.fireball_cooldown(), want_cd):
		return _fail("US-049 AC2: owned cooldown want %s got %s" % [want_cd, DmManager.fireball_cooldown()])
	if not _assert_cast_cost(want_cost):
		return false
	if not is_equal_approx(DmManager.fireball_cooldown_remaining(), want_cd):
		return _fail("US-049 AC2: remaining cooldown after cast want %s got %s" % [want_cd, DmManager.fireball_cooldown_remaining()])

	DmUnlocks.lock("full_cord")
	if DmUnlocks.is_owned("full_cord"):
		return _fail("US-049 AC3: lock must clear full_cord")
	if DmManager.ability_cost(Catalog.FIREBALL) != Catalog.COST_FIREBALL:
		return _fail("US-049 AC3: lock must restore baseline cost")
	if not is_equal_approx(DmManager.fireball_cooldown(), DmManager.FIREBALL_COOLDOWN):
		return _fail("US-049 AC3: lock must restore baseline cooldown")
	return true


func _assert_cast_cost(want_cost: int) -> bool:
	DmUnlocks.dm_unlocks[Catalog.FIREBALL] = true
	DmManager.clear_fireball_cooldown()
	DmManager.set_mana(want_cost)
	if not DmManager.launch_fireball(_spell_data()):
		return _fail("US-049: fireball at exact cost %d must launch" % want_cost)
	if DmManager.current_mana != 0:
		return _fail("US-049: mana after cost %d want 0 got %d" % [want_cost, DmManager.current_mana])
	return true


func _spell_data() -> Dictionary:
	return {
		"shooter_id": 1,
		"position": Vector2.ZERO,
		"target": Vector2(64, 64),
		"radius_bonus": 0,
		"base_damage_bonus": 0,
		"speed_bonus": 0,
	}


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
