extends Node


func _ready() -> void:
	if not _run_suite():
		return
	print("US-046 T-Shirt in December test passed")
	get_tree().quit(0)


func _run_suite() -> bool:
	DmUnlocks.reset_unlocks()
	DmManager.clear_blizzard_effects()
	DmManager.clear_frost_trail()
	if not is_equal_approx(DmManager.FROST_TRAIL_SIZE, DungeonGrid.CELL_PX / 4.0):
		return _fail("US-046: frost patch size must be 1/4 of a tile")
	if DmUnlocks.is_owned("tshirt_in_december"):
		return _fail("US-046 AC1: tshirt_in_december must start unowned")
	var world := Vector2(100.0, 200.0)
	if DmManager.stamp_frost_world(world):
		return _fail("US-046 AC1: unowned stamp_frost_world must no-op")
	if DmManager.frost_trail_count() != 0:
		return _fail("US-046 AC1: unowned frost trail must be empty")
	if not is_equal_approx(DmManager.blizzard_slow_factor_at(world), 1.0):
		return _fail("US-046 AC1: unowned world must not slow")

	DmUnlocks.unlock("tshirt_in_december")
	if not DmUnlocks.is_owned("tshirt_in_december"):
		return _fail("US-046 FR-001: force-own tshirt_in_december must stick")
	if not DmManager.stamp_frost_world(world):
		return _fail("US-046 AC2: owned stamp_frost_world must succeed")
	if DmManager.frost_trail_count() != 1:
		return _fail("US-046 AC2: owned trail count want 1 got %d" % DmManager.frost_trail_count())
	if not DmManager.frost_trail_covers_world(world):
		return _fail("US-046 AC2: trail must cover the stamp world position")
	if not is_equal_approx(DmManager.blizzard_slow_factor_at(world), DmManager.BLIZZARD_SLOW_FACTOR):
		return _fail("US-046 AC2: frost patch must slow at blizzard factor")
	var far: Vector2 = world + Vector2(DungeonGrid.CELL_PX, 0.0)
	if DmManager.frost_trail_covers_world(far):
		return _fail("US-046 AC2: frost must not snap to a full tile")
	if not is_equal_approx(DmManager.blizzard_slow_factor_at(far), 1.0):
		return _fail("US-046 AC2: a tile away must stay baseline speed")

	var dm_packed: PackedScene = load("res://dm/dm.tscn") as PackedScene
	if dm_packed == null:
		return _fail("US-046: dm.tscn missing")
	var dm_body: Node = dm_packed.instantiate()
	add_child(dm_body)
	if not (dm_body is DM):
		dm_body.queue_free()
		return _fail("US-046: dm.tscn must be a DM")
	var actor: DM = dm_body as DM
	var start: Vector2 = Vector2(50.0, 80.0)
	actor.global_position = start
	DmManager.dm = actor
	DmManager._tick_frost_trail()
	var stepped: Vector2 = start + Vector2(DmManager.FROST_TRAIL_SPACING + 1.0, 0.0)
	actor.global_position = stepped
	DmManager._tick_frost_trail()
	var under_feet: bool = DmManager.frost_trail_covers_world(stepped)
	dm_body.queue_free()
	DmManager.dm = null
	if not under_feet:
		return _fail("US-046 AC2: moving DM must stamp frost under their feet")

	var packed: Array = DmManager.pack_frost_trail()
	if packed.is_empty():
		return _fail("US-046 AC4: pack_frost_trail must include live patches")
	DmManager.apply_frost_trail(packed)
	if not DmManager.frost_trail_covers_world(world):
		return _fail("US-046 AC4: apply_frost_trail must restore world patches")

	DmUnlocks.lock("tshirt_in_december")
	if DmUnlocks.is_owned("tshirt_in_december"):
		return _fail("US-046 AC3: lock must clear tshirt_in_december")
	DmManager._tick_frost_trail()
	if DmManager.frost_trail_count() != 0:
		return _fail("US-046 AC3: lock must clear the frost trail")
	if not is_equal_approx(DmManager.blizzard_slow_factor_at(world), 1.0):
		return _fail("US-046 AC3: cleared trail must not slow")
	if DmManager.stamp_frost_world(world):
		return _fail("US-046 AC3: stamp after lock must no-op")
	return true


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
