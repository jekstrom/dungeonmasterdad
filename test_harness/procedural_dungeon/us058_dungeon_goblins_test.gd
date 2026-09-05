extends Node

const Catalog = preload("res://dm/dm_ability_catalog.gd")
const TICK := 1.0 / 60.0

func _ready() -> void:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager == null or not manager.has_method("generate_dungeon_contract"):
		_fail("US-058: DungeonGenerationManager missing")
		return

	var response: Dictionary = manager.generate_dungeon_contract({
		"requestId": "us058-goblins",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {
			"origin": {"x": 0, "y": 0},
			"size": {"x": 24, "y": 24}
		},
		"roomSize": 5,
		"roomCount": 4
	}, 1)
	if not response.get("ok", false):
		_fail("US-058: generate failed %s" % response)
		return
	var data: Dictionary = response.get("data", {})
	if not _assert_spawns(data):
		return
	if not await _assert_goblin_melee_damages_dm():
		return
	if not _assert_unlock_and_faction():
		return
	if not _assert_playground_generate_on_ready():
		return

	print("US-058 dungeon goblins test passed")
	get_tree().quit(0)


func _assert_spawns(data: Dictionary) -> bool:
	var start_set: Dictionary = {}
	var exit_set: Dictionary = {}
	var mid_set: Dictionary = {}
	var has_skeleton: bool = false
	var goblins: Array[Vector2i] = []
	for region in data.get("roomRegions", []):
		var role: String = str(region.get("role", ""))
		for point in region.get("cells", []):
			var cell: Vector2i = _as_cell(point)
			if role == "start":
				start_set[cell] = true
			elif role == "exit":
				exit_set[cell] = true
			elif role == "mid":
				mid_set[cell] = true
	for spawn in data.get("monsterSpawns", []):
		var type_id: String = str(spawn.get("monsterTypeId", ""))
		var cell: Vector2i = _as_cell(spawn.get("position", {}))
		if type_id == "skeleton":
			has_skeleton = true
		if type_id == "goblin":
			goblins.append(cell)
			if start_set.has(cell):
				return _fail("US-058: goblin in start room")
			if exit_set.has(cell):
				return _fail("US-058: goblin in exit room")
	if goblins.size() < DungeonConstants.MIN_DUNGEON_GOBLINS:
		return _fail("US-058: expected at least %d goblins, got %d" % [DungeonConstants.MIN_DUNGEON_GOBLINS, goblins.size()])
	if goblins.size() > DungeonConstants.MAX_DUNGEON_GOBLINS:
		return _fail("US-058: expected at most %d goblins, got %d" % [DungeonConstants.MAX_DUNGEON_GOBLINS, goblins.size()])
	if not has_skeleton:
		return _fail("US-058: skeletons must still spawn")
	return true


func _assert_goblin_melee_damages_dm() -> bool:
	if not multiplayer.is_server():
		return _fail("US-058: offline peer must be server")
	DmUnlocks.reset_unlocks()
	DmManager.fantasy_level = 0
	var dm: DM = load("res://dm/dm.tscn").instantiate() as DM
	if dm == null:
		return _fail("US-058: DM scene missing")
	dm.global_position = Vector2(64, 64)
	add_child(dm)
	dm.collision_layer = 0
	dm.collision_mask = 0
	dm.set_physics_process(false)
	dm.set_process(false)
	var dm_sm: Node = dm.get_node_or_null("DmStateMachine")
	if dm_sm:
		dm_sm.process_mode = Node.PROCESS_MODE_DISABLED
	var cam: Node = dm.get_node_or_null("Camera2D")
	if cam is Camera2D:
		(cam as Camera2D).enabled = false
	await get_tree().process_frame
	await get_tree().process_frame
	DmManager.dm = dm
	dm.invulnerable = false
	dm.set("_dead", false)
	dm.hitpoints = 6
	dm.max_hp = 6
	var goblin: Enemy = load("res://monsters/goblin.tscn").instantiate() as Enemy
	if goblin == null:
		return _fail("US-058: goblin must be an Enemy")
	goblin.global_position = Vector2(64, 80)
	add_child(goblin)
	goblin.collision_layer = 0
	goblin.collision_mask = 0
	goblin.raids_buildings = false
	goblin.aggro_faction = Enemy.AggroFaction.DM
	var sm: Node = goblin.get_node_or_null("EnemyStateMachine")
	if sm:
		sm.process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().process_frame
	await get_tree().process_frame
	var hurtbox: Hurtbox = goblin.get_node_or_null("Hurtbox") as Hurtbox
	if hurtbox == null:
		return _fail("US-058: goblin Hurtbox missing")
	if (hurtbox.collision_mask & 4) == 0:
		return _fail("US-058: goblin Hurtbox must scan the DM Hitbox layer")
	var hitbox: Hitbox = dm.get_node_or_null("Hitbox") as Hitbox
	if hitbox == null:
		return _fail("US-058: DM Hitbox missing")
	if goblin.acquire_aggro_target() != dm:
		return _fail("US-058: pre-exit goblin must acquire the DM")
	if not goblin.can_melee_current_target():
		return _fail("US-058: goblin must be in melee range of the DM")
	if not goblin.can_damage_dm():
		return _fail("US-058: pre-exit goblin must be allowed to damage the DM")
	hitbox.take_damage(hurtbox)
	if int(dm.hitpoints) != 5:
		return _fail("US-058: goblin Hurtbox must chip the DM Hitbox, got %s" % dm.hitpoints)
	dm.invulnerable = false
	dm.hitpoints = 6
	var aggro: Node = goblin.get_node_or_null("EnemyStateMachine/aggro")
	if sm == null or aggro == null:
		return _fail("US-058: goblin aggro state missing")
	sm.process_mode = Node.PROCESS_MODE_INHERIT
	sm.call("change_state", aggro)
	for _i in 3:
		sm.call("_process", TICK)
		sm.call("_physics_process", TICK)
	if int(dm.hitpoints) != 5:
		return _fail("US-058: goblin aggro melee must chip the DM via hitbox, got %s" % dm.hitpoints)
	dm.invulnerable = false
	goblin.aggro_faction = Enemy.AggroFaction.PLAYERS
	goblin.aggro_target = null
	if goblin.can_damage_dm():
		return _fail("US-058: post-exit goblin must not be allowed to damage the DM")
	var hp_after: int = int(dm.hitpoints)
	hitbox.take_damage(hurtbox)
	if int(dm.hitpoints) != hp_after:
		return _fail("US-058: post-exit goblin Hurtbox must not damage the DM")
	goblin.queue_free()
	dm.queue_free()
	await get_tree().process_frame
	return true


func _assert_unlock_and_faction() -> bool:
	DmUnlocks.reset_unlocks()
	DmHud.turn_on()
	if DmHud.spawn_goblin != null and DmHud.spawn_goblin.visible:
		return _fail("US-058: goblin HUD must be hidden before exit")
	DmManager.set_mana(20)
	if DmManager.try_cast(Catalog.GOBLIN):
		return _fail("US-058: locked goblin summon must refuse")
	if DmManager.current_mana != 20:
		return _fail("US-058: locked goblin summon must not spend mana")

	var packed: PackedScene = load("res://monsters/goblin.tscn") as PackedScene
	if packed == null:
		return _fail("US-058: goblin scene missing")
	var goblin: Enemy = packed.instantiate() as Enemy
	if goblin == null:
		return _fail("US-058: goblin must be an Enemy")
	add_child(goblin)
	goblin.raids_buildings = true
	goblin.add_to_group("goblins")
	goblin.aggro_faction = Enemy.AggroFaction.DM
	if not goblin.aggros_on_dm():
		return _fail("US-058: pre-exit goblin must aggro the DM")

	DmManager._dm_was_in_dungeon = false
	DmManager._tick_goblin_exit_unlock()
	if DmUnlocks.is_owned(Catalog.UNLOCK_GOBLIN):
		return _fail("US-058: tick must not unlock goblin before the DM has been in the dungeon")

	DmManager.notify_first_dungeon_exit()
	if not DmUnlocks.is_owned(Catalog.UNLOCK_GOBLIN):
		return _fail("US-058: first exit must unlock goblin")
	if DmHud.spawn_goblin != null and not DmHud.spawn_goblin.visible:
		return _fail("US-058: goblin HUD must show after exit")
	if goblin.aggro_faction != Enemy.AggroFaction.PLAYERS:
		return _fail("US-058: leftover goblin must stop hunting the DM")
	if goblin.aggros_on_dm():
		return _fail("US-058: post-exit goblin must not aggro the DM")

	DmManager.notify_first_dungeon_exit()
	if not DmUnlocks.is_owned(Catalog.UNLOCK_GOBLIN):
		return _fail("US-058: second exit must leave goblin unlocked")

	if not DmManager.try_cast(Catalog.GOBLIN):
		return _fail("US-058: unlocked goblin summon must succeed with mana")
	if DmManager.current_mana != 0:
		return _fail("US-058: goblin summon must cost 20 mana")

	goblin.queue_free()
	return true


func _assert_playground_generate_on_ready() -> bool:
	var text: String = FileAccess.get_file_as_string("res://playground.tscn")
	if text.find("generate_on_ready = false") < 0:
		return _fail("US-058: playground must keep generate_on_ready false")
	return true


func _as_cell(raw_value: Variant) -> Vector2i:
	if raw_value is Vector2i:
		return raw_value
	if raw_value is Dictionary:
		return Vector2i(int(raw_value.get("x", 0)), int(raw_value.get("y", 0)))
	return Vector2i.ZERO


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
