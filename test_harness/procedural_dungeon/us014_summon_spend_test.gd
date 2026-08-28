extends Node

const Catalog = preload("res://dm/dm_ability_catalog.gd")

var _spawn_gremlin_count: int = 0
var _spawn_knight_count: int = 0

func _ready() -> void:
	if not DmManager.spawn_gremlin_cast.is_connected(_on_spawn_gremlin):
		DmManager.spawn_gremlin_cast.connect(_on_spawn_gremlin)
	if not DmManager.spawn_knight_cast.is_connected(_on_spawn_knight):
		DmManager.spawn_knight_cast.connect(_on_spawn_knight)

	var fantasy_before: int = DmManager.fantasy_level
	DmManager.set_mana(0)
	DmHud._on_gremlin_button_pressed()
	DmHud._on_knight_button_pressed()
	if _spawn_gremlin_count != 0 or _spawn_knight_count != 0:
		_fail("US-014 T004: 0 mana HUD summon must not spawn")
		return
	if DmManager.current_mana != 0:
		_fail("US-014 T004: 0 mana HUD summon must leave mana at 0")
		return
	if DmManager.fantasy_level != fantasy_before:
		_fail("US-014 T004: refused summon must not change fantasy_level")
		return

	DmManager.set_mana(25)
	DmHud._on_gremlin_button_pressed()
	if _spawn_gremlin_count != 1:
		_fail("US-014 T004: gremlin HUD with mana must spawn once, got %d" % _spawn_gremlin_count)
		return
	if DmManager.current_mana != 5:
		_fail("US-014 T004: gremlin must cost 20, mana is %d" % DmManager.current_mana)
		return
	if DmManager.fantasy_level != fantasy_before:
		_fail("US-014 T004: gremlin must not tax fantasy_level")
		return

	DmUnlocks.dm_unlocks[Catalog.KNIGHTLING] = true
	DmManager.set_mana(40)
	DmHud._on_knight_button_pressed()
	if _spawn_knight_count != 1:
		_fail("US-014 T004: knightling HUD with mana must spawn once, got %d" % _spawn_knight_count)
		return
	if DmManager.current_mana != 0:
		_fail("US-014 T004: knightling must cost 40, mana is %d" % DmManager.current_mana)
		return
	if DmManager.fantasy_level != fantasy_before:
		_fail("US-014 T004: knightling must not tax fantasy_level")
		return

	var gremlin_before: int = _spawn_gremlin_count
	DmManager.set_mana(25)
	DmManager.request_cast(Catalog.FIREBALL)
	if DmManager.current_mana != 25 or _spawn_gremlin_count != gremlin_before:
		_fail("US-014 T004: request_cast must not handle fireball")
		return

	DmManager.set_mana(25)
	DmManager.request_cast_rpc(Catalog.GREMLIN)
	if DmManager.current_mana != 25:
		_fail("US-014 T004: non-DM RPC must not spend mana")
		return
	if _spawn_gremlin_count != gremlin_before:
		_fail("US-014 T004: non-DM RPC must not spawn")
		return

	DmManager.set_mana(0)
	print("US-014 T004 summon spend test passed")
	get_tree().quit(0)

func _on_spawn_gremlin() -> void:
	_spawn_gremlin_count += 1

func _on_spawn_knight() -> void:
	_spawn_knight_count += 1

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
