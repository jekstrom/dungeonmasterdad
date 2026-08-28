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

	DmUnlocks.dm_unlocks[Catalog.FIREBALL] = false
	DmUnlocks.dm_unlocks[Catalog.UNLOCK_BEMIDJI_BLIZZARD] = false
	DmManager.set_mana(0)
	DmHud.turn_on()
	var fantasy_before: int = DmManager.fantasy_level
	var refuse_ids: Array[String] = [
		Catalog.GREMLIN,
		Catalog.KNIGHTLING,
		Catalog.FIREBALL,
		Catalog.BEMIDJI_BLIZZARD
	]
	for ability_id in refuse_ids:
		if DmManager.try_cast(ability_id):
			_fail("US-014 independent: %s must refuse at 0 mana" % ability_id)
			return
		if DmManager.current_mana != 0:
			_fail("US-014 independent: refuse must leave mana at 0")
			return
	DmHud._on_gremlin_button_pressed()
	DmHud._on_knight_button_pressed()
	if _spawn_gremlin_count != 0 or _spawn_knight_count != 0 or _spell_cast_count != 0:
		_fail("US-014 independent: 0 mana HUD must not spawn or cast")
		return
	if not _hud_mana_text_is("0/100"):
		_fail("US-014 independent: HUD must show 0/100 at start")
		return

	var dew: ItemData = load("res://pickups/mtdew.tres") as ItemData
	if dew == null or dew.pickup_char != "dm_only":
		_fail("US-014 independent: green Dew must be a dm_only ItemData")
		return
	dew.use()
	if DmManager.current_mana != 25:
		_fail("US-014 independent: Dew pickup must grant 25 mana")
		return
	if not _hud_mana_text_is("25/100"):
		_fail("US-014 independent: HUD must show 25/100 after Dew")
		return

	DmHud._on_gremlin_button_pressed()
	if _spawn_gremlin_count != 1:
		_fail("US-014 independent: gremlin must spawn once after Dew")
		return
	if DmManager.current_mana != 5:
		_fail("US-014 independent: gremlin must spend 20, mana is %d" % DmManager.current_mana)
		return
	if DmManager.fantasy_level != fantasy_before:
		_fail("US-014 independent: gremlin must not tax Fantasy Level")
		return
	if not _hud_mana_text_is("5/100"):
		_fail("US-014 independent: HUD must show 5/100 after gremlin")
		return

	if DmManager.try_cast(Catalog.GREMLIN) or DmManager.try_cast(Catalog.FIREBALL) or DmManager.try_cast(Catalog.BEMIDJI_BLIZZARD):
		_fail("US-014 independent: short mana must refuse")
		return
	DmHud._on_gremlin_button_pressed()
	if _spawn_gremlin_count != 1 or DmManager.current_mana != 5:
		_fail("US-014 independent: second gremlin at 5 mana must refuse")
		return

	DmManager.set_mana(0)
	if DmManager.try_cast(Catalog.GREMLIN):
		_fail("US-014 independent: gremlin must refuse again at 0 mana")
		return
	if DmManager.current_mana != 0:
		_fail("US-014 independent: final refuse must leave mana at 0")
		return

	print("US-014 independent test passed")
	get_tree().quit(0)

func _hud_mana_text_is(expected: String) -> bool:
	var label: Label = DmHud.get_node_or_null("%ManaLabel") as Label
	return label != null and label.text == expected

func _on_spawn_gremlin() -> void:
	_spawn_gremlin_count += 1

func _on_spawn_knight() -> void:
	_spawn_knight_count += 1

func _on_spell_cast(_spell_id: String, _spell_data: Dictionary) -> void:
	_spell_cast_count += 1

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
