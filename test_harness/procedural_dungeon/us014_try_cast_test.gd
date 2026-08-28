extends Node

const Catalog = preload("res://dm/dm_ability_catalog.gd")

var _spawn_gremlin_count: int = 0
var _spawn_knight_count: int = 0
var _spell_cast_count: int = 0

func _ready() -> void:
	if not DmManager.spawn_gremlin_cast.is_connected(_on_spawn_gremlin):
		DmManager.spawn_gremlin_cast.connect(_on_spawn_gremlin)
	if not DmManager.spawn_knight_cast.is_connected(_on_spawn_knight):
		DmManager.spawn_knight_cast.connect(_on_spawn_knight)
	if not SignalBus.spell_cast.is_connected(_on_spell_cast):
		SignalBus.spell_cast.connect(_on_spell_cast)

	DmUnlocks.dm_unlocks["fireball"] = false
	DmUnlocks.dm_unlocks["bemidji_blizzard"] = false
	DmUnlocks.dm_unlocks["dad_all_powerful"] = false
	DmManager.set_mana(0)
	var fantasy_before: int = DmManager.fantasy_level

	if DmManager.try_cast("not_an_ability"):
		_fail("US-014 T003: unknown id must fail")
		return
	if DmManager.current_mana != 0:
		_fail("US-014 T003: unknown id must not change mana")
		return

	for ability_id in [Catalog.GREMLIN, Catalog.KNIGHTLING, Catalog.FIREBALL, Catalog.BEMIDJI_BLIZZARD]:
		if DmManager.try_cast(ability_id):
			_fail("US-014 T003: %s must refuse at 0 mana" % ability_id)
			return
		if DmManager.current_mana != 0:
			_fail("US-014 T003: %s refuse must leave mana at 0" % ability_id)
			return

	if DmManager.try_cast(Catalog.DAD_ALL_POWERFUL):
		_fail("US-014 T003: dad_all_powerful must fail while locked even at cost 0")
		return
	if DmManager.current_mana != 0:
		_fail("US-014 T003: locked dad_all_powerful must not change mana")
		return

	DmManager.set_mana(10)
	if DmManager.try_cast(Catalog.GREMLIN):
		_fail("US-014 T003: gremlin must fail when mana 10 < cost 20")
		return
	if DmManager.current_mana != 10:
		_fail("US-014 T003: short gremlin cast must leave mana unchanged")
		return

	DmManager.set_mana(25)
	if DmManager.try_cast(Catalog.FIREBALL):
		_fail("US-014 T003: locked fireball must fail with enough mana")
		return
	if DmManager.current_mana != 25:
		_fail("US-014 T003: locked fireball must not spend mana")
		return

	DmUnlocks.dm_unlocks["fireball"] = true
	if not DmManager.try_cast(Catalog.FIREBALL):
		_fail("US-014 T003: unlocked fireball must succeed at 25 mana")
		return
	if DmManager.current_mana != 10:
		_fail("US-014 T003: fireball must deduct 15, got %d" % DmManager.current_mana)
		return
	if DmManager.try_cast(Catalog.GREMLIN):
		_fail("US-014 T003: gremlin must fail on remaining 10 mana")
		return
	if DmManager.current_mana != 10:
		_fail("US-014 T003: failed gremlin after fireball must leave mana at 10")
		return

	DmManager.set_mana(25)
	if not DmManager.try_cast(Catalog.GREMLIN):
		_fail("US-014 T003: first gremlin at 25 mana must succeed")
		return
	if DmManager.current_mana != 5:
		_fail("US-014 T003: first gremlin must leave mana 5, got %d" % DmManager.current_mana)
		return
	if DmManager.try_cast(Catalog.GREMLIN):
		_fail("US-014 T003: second gremlin in the same frame must fail")
		return
	if DmManager.current_mana != 5:
		_fail("US-014 T003: second gremlin must leave mana at 5")
		return
	if DmManager.fantasy_level != fantasy_before:
		_fail("US-014 T003: try_cast must not change fantasy_level")
		return

	if _spawn_gremlin_count != 0 or _spawn_knight_count != 0 or _spell_cast_count != 0:
		_fail("US-014 T003: try_cast must not spawn or emit spell_cast")
		return

	DmManager.set_mana(0)
	print("US-014 T003 try_cast test passed")
	get_tree().quit(0)

func _on_spawn_gremlin() -> void:
	_spawn_gremlin_count += 1

func _on_spawn_knight() -> void:
	_spawn_knight_count += 1

func _on_spell_cast(_spell_id: String, _spell_data: Dictionary) -> void:
	_spell_cast_count += 1

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
