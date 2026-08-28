extends Node

const Catalog = preload("res://dm/dm_ability_catalog.gd")

func _ready() -> void:
	if not Catalog.is_known(Catalog.GREMLIN):
		_fail("US-014 T002: gremlin must be a known ability")
		return
	if Catalog.cost(Catalog.GREMLIN) != 20:
		_fail("US-014 T002: gremlin cost must be 20")
		return
	if not Catalog.unlock_id(Catalog.GREMLIN).is_empty():
		_fail("US-014 T002: gremlin must have no unlock gate")
		return

	if Catalog.cost(Catalog.KNIGHTLING) != 40:
		_fail("US-014 T002: knightling cost must be 40")
		return
	if not Catalog.unlock_id(Catalog.KNIGHTLING).is_empty():
		_fail("US-014 T002: knightling unlock must stay empty (US-016)")
		return

	if Catalog.cost(Catalog.FIREBALL) != 15:
		_fail("US-014 T002: fireball cost must be 15")
		return
	if Catalog.unlock_id(Catalog.FIREBALL) != "fireball":
		_fail("US-014 T002: fireball unlock_id must be fireball")
		return

	if Catalog.cost(Catalog.BEMIDJI_BLIZZARD) != 30:
		_fail("US-014 T002: bemidji_blizzard cost must be 30")
		return
	if Catalog.unlock_id(Catalog.BEMIDJI_BLIZZARD) != "bemidji_blizzard":
		_fail("US-014 T002: bemidji_blizzard unlock_id mismatch")
		return

	if Catalog.cost(Catalog.DAD_ALL_POWERFUL) != 0:
		_fail("US-014 T002: dad_all_powerful cost must be 0")
		return
	if Catalog.unlock_id(Catalog.DAD_ALL_POWERFUL) != "dad_all_powerful":
		_fail("US-014 T002: dad_all_powerful unlock_id mismatch")
		return

	var unknown_id: String = "not_an_ability"
	if Catalog.is_known(unknown_id):
		_fail("US-014 T002: unknown id must not be known")
		return
	if Catalog.cost(unknown_id) != Catalog.UNKNOWN_COST:
		_fail("US-014 T002: unknown id must not use a real mana cost")
		return
	if not Catalog.unlock_id(unknown_id).is_empty():
		_fail("US-014 T002: unknown id unlock query must not throw or invent a key")
		return
	if Catalog.is_known("code_red") or Catalog.is_known("baja_blast"):
		_fail("US-014 T002: flavor cans must not be catalog abilities")
		return

	print("US-014 T002 ability catalog test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
