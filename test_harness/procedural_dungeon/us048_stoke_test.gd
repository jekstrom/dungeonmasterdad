extends Node

const Catalog = preload("res://dm/dm_ability_catalog.gd")
const Planner = preload("res://scripts/procedural_dungeon/pickup_spawn_planner.gd")

var _last_spell: Dictionary = {}


func _ready() -> void:
	if not SignalBus.spell_cast.is_connected(_on_spell_cast):
		SignalBus.spell_cast.connect(_on_spell_cast)
	if not _run_suite():
		return
	print("US-048 Stoke test passed")
	get_tree().quit(0)


func _run_suite() -> bool:
	DmUnlocks.reset_unlocks()
	if DmUnlocks.is_owned("stoke"):
		return _fail("US-048 AC1: stoke must start unowned")
	if not is_equal_approx(DmManager.fireball_radius(), DmManager.FIREBALL_RADIUS):
		return _fail("US-048 AC1: unowned fireball_radius must be %s got %s" % [DmManager.FIREBALL_RADIUS, DmManager.fireball_radius()])
	if not _assert_launch_radius(false):
		return false
	DmUnlocks.unlock("stoke")
	if not DmUnlocks.is_owned("stoke"):
		return _fail("US-048 FR-001: force-own stoke must stick")
	var want: float = DmManager.FIREBALL_RADIUS * DmManager.FIREBALL_STOKE_SCALE
	if not is_equal_approx(DmManager.fireball_radius(), want):
		return _fail("US-048 AC2: owned fireball_radius want %s got %s" % [want, DmManager.fireball_radius()])
	if not _assert_launch_radius(true):
		return false
	if not is_equal_approx(DmManager.FIREBALL_STOKE_SCALE, 2.0):
		return _fail("US-048: Stoke explosion scale must be 2x")
	if not _assert_explosion_visual_scale():
		return false
	DmUnlocks.lock("stoke")
	if DmUnlocks.is_owned("stoke"):
		return _fail("US-048 AC3: lock must clear stoke")
	if not is_equal_approx(DmManager.fireball_radius(), DmManager.FIREBALL_RADIUS):
		return _fail("US-048 AC3: lock must restore baseline radius")
	if not _assert_code_red_in_start_room():
		return false
	return true


func _assert_explosion_visual_scale() -> bool:
	var packed: PackedScene = load("res://spells/fireball/fireball_spell.tscn") as PackedScene
	if packed == null:
		return _fail("US-048: fireball_spell.tscn missing")
	var ball: Node = packed.instantiate()
	add_child(ball)
	if not (ball is FireballSpell):
		ball.queue_free()
		return _fail("US-048: fireball_spell.tscn must be FireballSpell")
	var spell: FireballSpell = ball as FireballSpell
	spell.radius = DmManager.FIREBALL_RADIUS * 2.0
	spell._apply_explosion_scale()
	var boom: Sprite2D = spell.get_node_or_null("Explosion") as Sprite2D
	var ok: bool = boom != null and is_equal_approx(boom.scale.x, 2.0) and is_equal_approx(boom.scale.y, 2.0)
	ball.queue_free()
	if not ok:
		return _fail("US-048: Stoke explosion sprite must scale 2x")
	return true


func _assert_launch_radius(owned: bool) -> bool:
	DmUnlocks.dm_unlocks[Catalog.FIREBALL] = true
	DmManager.set_mana(100)
	_last_spell = {}
	var data := {
		"shooter_id": 1,
		"position": Vector2.ZERO,
		"target": Vector2(64, 64),
		"radius_bonus": 99,
		"base_damage_bonus": 0,
		"speed_bonus": 0,
	}
	if not DmManager.launch_fireball(data):
		return _fail("US-048: launch_fireball must succeed")
	var want: float = DmManager.FIREBALL_RADIUS * DmManager.FIREBALL_STOKE_SCALE if owned else DmManager.FIREBALL_RADIUS
	var got: float = float(_last_spell.get("radius", -1.0))
	if absf(got - want) > 0.01:
		return _fail("US-048: launched radius %s want %s (owned=%s)" % [got, want, owned])
	if absf(float(data.get("radius_bonus", 0.0)) - (want - DmManager.FIREBALL_RADIUS)) > 0.01:
		return _fail("US-048: host must overwrite client radius_bonus")
	return true


func _assert_code_red_in_start_room() -> bool:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager == null or not manager.has_method("generate_dungeon_contract"):
		return _fail("US-048: DungeonGenerationManager missing")
	var response: Dictionary = manager.generate_dungeon_contract({
		"requestId": "us048-start-room-code-red",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {
			"origin": {"x": 0, "y": 0},
			"size": {"x": 24, "y": 24}
		}
	}, 1)
	if not response.get("ok", false):
		return _fail("US-048: generation failed %s" % response)
	var data: Dictionary = response.get("data", {})
	var entrance: Vector2i = _as_cell(data.get("entrance", {}))
	var exit_cell: Vector2i = _as_cell(data.get("exit", {}))
	var start_set: Dictionary = {}
	for region in data.get("roomRegions", []):
		if str(region.get("role", "")) != "start":
			continue
		for point in region.get("cells", []):
			start_set[_as_cell(point)] = true
	var code_reds: int = 0
	for pickup in data.get("itemPickups", []):
		if str(pickup.get("item_type", "")) != Planner.CODE_RED_PATH:
			continue
		var cell: Vector2i = _as_cell(pickup.get("position", {}))
		if cell == entrance or cell == exit_cell:
			return _fail("US-048: Code Red must not sit on entrance or exit")
		if not start_set.has(cell):
			return _fail("US-048: Code Red must be in the start room")
		code_reds += 1
	if code_reds < 1:
		return _fail("US-048: start room must contain a Code Red can")
	return true


func _on_spell_cast(_spell_id: String, spell_data: Dictionary) -> void:
	_last_spell = spell_data


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
