extends Node

## US-017 T007: blizzard HUD icons and icy pocket overlay.
## user_stories/tasks/US-017/T007-blizzard-hud-overlay.md

const Catalog = preload("res://dm/dm_ability_catalog.gd")
const POCKET_SIZE := Vector2i(3, 3)

var _level: Node
var _reality: Node
var _fantasy: Node
var _interior := Rect2i(0, 0, 16, 10)
var _dungeon := Rect2i(8, 2, 8, 6)
var _started_spells: Array[String] = []


func _ready() -> void:
	if not SignalBus.start_spell_cast.is_connected(_on_start_spell_cast):
		SignalBus.start_spell_cast.connect(_on_start_spell_cast)
	DmManager.clear_blizzard_effects()
	DmUnlocks.reset_unlocks()
	DmManager.fantasy_level = 0
	PlayerManager.reality_level = 0
	if not _assert_hud_locked():
		return
	if not _assert_hud_unlock_and_icons():
		return
	if not await _setup_map():
		return
	if not await _assert_ice_overlay_and_expire():
		return
	print("US-017 T007 blizzard HUD test passed")
	get_tree().quit(0)


func _on_start_spell_cast(spell_id: String) -> void:
	_started_spells.append(spell_id)


func _assert_hud_locked() -> bool:
	DmUnlocks.reset_unlocks()
	DmHud.turn_on()
	if DmHud.blizzard == null:
		return _fail("US-017 T007: Blizzard HUD control missing")
	if DmHud.blizzard.visible:
		return _fail("US-017 T007: blizzard control must be hidden while locked")
	var mana_before: int = DmManager.current_mana
	var casts_before: int = _started_spells.size()
	DmHud._on_blizzard_button_pressed()
	if _started_spells.size() != casts_before:
		return _fail("US-017 T007: locked HUD press must not start targeting")
	if DmManager.current_mana != mana_before:
		return _fail("US-017 T007: locked HUD press must not spend mana")
	return true


func _assert_hud_unlock_and_icons() -> bool:
	DmUnlocks.unlock(Catalog.BEMIDJI_BLIZZARD)
	if not DmHud.blizzard.visible:
		return _fail("US-017 T007: blizzard control must show after unlock")
	DmHud.turn_off()
	DmHud.turn_on()
	if not DmHud.blizzard.visible:
		return _fail("US-017 T007: late turn_on must read bemidji_blizzard unlock")
	var btn: TextureButton = DmHud.cast_blizzard_button
	if btn == null or btn.texture_normal == null:
		return _fail("US-017 T007: blizzard TextureButton missing normal texture")
	var normal_path: String = str(btn.texture_normal.resource_path)
	if normal_path.find("spells/blizzard/blizzard.png") == -1:
		return _fail("US-017 T007: HUD must use spells/blizzard/blizzard.png, got %s" % normal_path)
	if normal_path.find("sprites/blizzard_hud") != -1:
		return _fail("US-017 T007: HUD must not use leftover sprites/blizzard_hud.png")
	if btn.texture_pressed == null or str(btn.texture_pressed.resource_path).find("spells/blizzard/blizzard_pressed.png") == -1:
		return _fail("US-017 T007: HUD pressed texture must be spells/blizzard/blizzard_pressed.png")
	DmManager.set_mana(0)
	if not DmHud.blizzard.visible:
		return _fail("US-017 T007: unlocked blizzard HUD must stay visible at 0 mana")
	var casts_before: int = _started_spells.size()
	DmHud._on_blizzard_button_pressed()
	if _started_spells.size() != casts_before + 1:
		return _fail("US-017 T007: unlocked HUD press must start targeting")
	if _started_spells[_started_spells.size() - 1] != Catalog.BEMIDJI_BLIZZARD:
		return _fail("US-017 T007: targeting spell_id must be bemidji_blizzard")
	if DmManager.current_mana != 0:
		return _fail("US-017 T007: HUD button-down must not spend mana (US-014 confirm spend)")
	return true


func _setup_map() -> bool:
	_level = Node2D.new()
	_level.set_script(load("res://_globals/level_manager.gd"))
	_level.add_to_group("level_manager")
	add_child(_level)
	await get_tree().process_frame
	_level.apply_map_interior(_interior, _dungeon)
	await get_tree().process_frame
	_level.rebuild_outside_fill()
	await get_tree().process_frame
	_reality = load("res://zones/reality_zone.tscn").instantiate()
	_reality.add_to_group("RealityZone")
	add_child(_reality)
	_fantasy = load("res://zones/fantasy_zone.tscn").instantiate()
	add_child(_fantasy)
	await get_tree().process_frame
	await get_tree().physics_frame
	if _fantasy == null or _reality == null:
		return _fail("US-017 T007: failed to instantiate zones")
	return true


func _assert_ice_overlay_and_expire() -> bool:
	DmUnlocks.dm_unlocks[Catalog.BEMIDJI_BLIZZARD] = true
	DmManager.set_mana(100)
	var origin: Vector2i = _pocket_origin()
	if not DmManager.launch_blizzard(_spell_at(origin)):
		return _fail("US-017 T007: unlocked launch_blizzard must succeed")
	var ice: int = _ice_sprite_count(_fantasy)
	if ice <= 0:
		return _fail("US-017 T007: live blizzard pocket must show blizzard_overlay.png")
	if _wrong_overlay_on_pocket(_fantasy):
		return _fail("US-017 T007: pocket overlay must be sprites/blizzard_overlay.png, not grass/home/dungeon")
	var covered: int = _covered_cell_count(origin)
	if ice != covered:
		return _fail("US-017 T007: ice sprites %d expected %d pocket cells" % [ice, covered])
	var pocket: Dictionary = _live_blizzard_pocket()
	if pocket.is_empty():
		return _fail("US-017 T007: missing live pocket dict")
	var expires_at: float = float(pocket.get("expires_at", 0.0))
	_fantasy.expire_due(expires_at + 0.01)
	if _ice_sprite_count(_fantasy) != 0:
		return _fail("US-017 T007: ice overlay must clear on pocket expire")
	if DmManager.live_blizzard_count() != 0:
		return _fail("US-017 T007: blizzard effect must drop with expire")
	return true


func _ice_sprite_count(zone: Node) -> int:
	var overlay: Node = zone.get_node_or_null("PocketOverlay")
	if overlay == null:
		return 0
	var n: int = 0
	for child in overlay.get_children():
		if not (child is Sprite2D):
			continue
		var sprite: Sprite2D = child
		if sprite.texture == null:
			continue
		if str(sprite.texture.resource_path).find("blizzard_overlay.png") != -1:
			n += 1
	return n


func _wrong_overlay_on_pocket(zone: Node) -> bool:
	var overlay: Node = zone.get_node_or_null("PocketOverlay")
	if overlay == null:
		return true
	for child in overlay.get_children():
		if not (child is Sprite2D):
			continue
		var sprite: Sprite2D = child
		if sprite.texture == null:
			return true
		var path: String = str(sprite.texture.resource_path)
		if path.find("blizzard_overlay.png") == -1:
			return true
		if path.find("fantasy_home_overlay") != -1:
			return true
		if path.find("fantasy_pocket_overlay") != -1:
			return true
	return false


func _covered_cell_count(origin: Vector2i) -> int:
	var n: int = 0
	for y in range(origin.y, origin.y + POCKET_SIZE.y):
		for x in range(origin.x, origin.x + POCKET_SIZE.x):
			var cell := Vector2i(x, y)
			if _interior.has_point(cell):
				n += 1
	return n


func _spell_at(origin: Vector2i) -> Dictionary:
	return {
		"target": DungeonGrid.to_world_center(origin + Vector2i(1, 1)),
		"origin": origin,
		"size": POCKET_SIZE,
		"duration": DmManager.BLIZZARD_DURATION,
		"slow_factor": DmManager.BLIZZARD_SLOW_FACTOR,
	}


func _pocket_origin() -> Vector2i:
	var home: Rect2i = _reality.home_rect
	var origin: Vector2i = Vector2i(home.position.x, home.position.y + 4)
	if origin.y + POCKET_SIZE.y > home.end.y:
		origin.y = home.position.y
	if origin.x < _interior.position.x:
		origin.x = _interior.position.x
	if origin.y < _interior.position.y:
		origin.y = _interior.position.y
	if origin.x + POCKET_SIZE.x > _interior.end.x:
		origin.x = _interior.end.x - POCKET_SIZE.x
	if origin.y + POCKET_SIZE.y > _interior.end.y:
		origin.y = _interior.end.y - POCKET_SIZE.y
	return origin


func _live_blizzard_pocket() -> Dictionary:
	if _fantasy.claim.pockets.is_empty():
		return {}
	return _fantasy.claim.pockets[_fantasy.claim.pockets.size() - 1]


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
