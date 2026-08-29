extends Node

## US-017 T004: boss death unlocks bemidji_blizzard and grants the Baja Blast can.
## user_stories/tasks/US-017/T004-death-unlock-can.md
## Cast pocket + slow is T005 — this test must not plant a Fantasy pocket.

const Catalog = preload("res://dm/dm_ability_catalog.gd")
const BajaBossScript = preload("res://monsters/baja_boss.gd")
const BOSS_SCENE := "res://monsters/baja_boss.tscn"
const BAJA_CAN := "res://pickups/bajablast/bajablast.tres"
const BAJA_TEX := "res://pickups/bajablast/bajablast.png"

var _drops: Array = []
var _pockets: int = 0


func _ready() -> void:
	if not SignalBus.on_item_drop.is_connected(_on_item_drop):
		SignalBus.on_item_drop.connect(_on_item_drop)
	if not SignalBus.fantasy_pocket_requested.is_connected(_on_pocket):
		SignalBus.fantasy_pocket_requested.connect(_on_pocket)
	if not SignalBus.fantasy_pocket_created.is_connected(_on_pocket_created):
		SignalBus.fantasy_pocket_created.connect(_on_pocket_created)

	if not _assert_locked_cast():
		return
	if not await _assert_boss_death_unlock_and_can():
		return
	print("US-017 T004 boss unlock test passed")
	get_tree().quit(0)


func _assert_locked_cast() -> bool:
	DmUnlocks.reset_unlocks()
	if bool(DmUnlocks.dm_unlocks.get("bemidji_blizzard", true)):
		_fail("US-017 T004: bemidji_blizzard must start locked after reset_unlocks")
		return false
	if not multiplayer.is_server():
		_fail("US-017 T004: offline peer must be server for try_cast")
		return false
	DmManager.set_mana(100)
	if DmManager.current_mana != 100:
		_fail("US-017 T004: failed to set mana to 100, got %d" % DmManager.current_mana)
		return false
	var cast_ok: bool = DmManager.try_cast(Catalog.BEMIDJI_BLIZZARD)
	if cast_ok:
		_fail("US-017 T004: locked try_cast(bemidji_blizzard) must return false")
		return false
	if DmManager.current_mana != 100:
		_fail("US-017 T004: locked cast must not spend mana, got %d" % DmManager.current_mana)
		return false
	if _pockets != 0:
		_fail("US-017 T004: locked cast must not plant a Fantasy pocket")
		return false
	return true


func _assert_boss_death_unlock_and_can() -> bool:
	var packed: PackedScene = load(BOSS_SCENE) as PackedScene
	if packed == null:
		_fail("US-017 T004: failed to load baja_boss.tscn")
		return false
	var boss: Node = packed.instantiate()
	if boss == null:
		_fail("US-017 T004: failed to instantiate baja_boss.tscn")
		return false
	add_child(boss)
	await get_tree().process_frame
	await get_tree().process_frame
	if not (boss is BajaBossScript):
		_fail("US-017 T004: instantiated node is not BajaBoss")
		return false
	if not multiplayer.is_server():
		_fail("US-017 T004: die() must run as server")
		return false

	var can_data: ItemData = load(BAJA_CAN) as ItemData
	if can_data == null:
		_fail("US-017 T004: %s must load as ItemData" % BAJA_CAN)
		return false
	if can_data.texture == null or str(can_data.texture.resource_path) != BAJA_TEX:
		_fail("US-017 T004: can must use %s, got %s" % [BAJA_TEX, can_data.texture])
		return false
	var db_can: ItemData = ItemDatabase.get_item(BAJA_CAN)
	if db_can == null:
		_fail("US-017 T004: ItemDatabase must resolve %s" % BAJA_CAN)
		return false

	_drops.clear()
	var drop_pos: Vector2 = (boss as Node2D).global_position
	boss.call("die")
	await get_tree().process_frame

	if not bool(DmUnlocks.dm_unlocks.get("bemidji_blizzard", false)):
		_fail("US-017 T004: host die() must unlock bemidji_blizzard")
		return false
	if not _has_baja_drop(drop_pos):
		_fail("US-017 T004: host die() must drop bajablast can, drops=%s" % _drops)
		return false
	if _pockets != 0:
		_fail("US-017 T004: death must not plant a Fantasy pocket (T005)")
		return false

	boss.call("die")
	await get_tree().process_frame
	if not bool(DmUnlocks.dm_unlocks.get("bemidji_blizzard", false)):
		_fail("US-017 T004: second die() must leave bemidji_blizzard unlocked")
		return false
	var baja_drops := 0
	for drop in _drops:
		if str(drop.get("item_type", "")).find("bajablast") != -1:
			baja_drops += 1
	if baja_drops != 1:
		_fail("US-017 T004: dying twice must drop the can once, got %d" % baja_drops)
		return false
	if _pockets != 0:
		_fail("US-017 T004: second die() must not plant a Fantasy pocket")
		return false
	return true


func _has_baja_drop(expected_pos: Vector2) -> bool:
	for drop in _drops:
		var item_type: String = str(drop.get("item_type", ""))
		if item_type != BAJA_CAN and item_type.find("bajablast") == -1:
			continue
		var pos: Variant = drop.get("position", Vector2.INF)
		if pos is Vector2 and (pos as Vector2).distance_to(expected_pos) <= 1.0:
			return true
		if pos is Vector2:
			return true
	var pickups: Array = []
	_collect_pickups(self, pickups)
	for pickup in pickups:
		var data: Variant = pickup.get("item_data")
		if data is ItemData:
			var tex: Texture2D = (data as ItemData).texture
			if tex != null and str(tex.resource_path).find("bajablast") != -1:
				return true
			if str((data as ItemData).resource_path).find("bajablast") != -1:
				return true
	return false


func _collect_pickups(node: Node, out: Array) -> void:
	if node is ItemPickup:
		out.append(node)
	for child in node.get_children():
		_collect_pickups(child, out)


func _on_item_drop(item_data: Dictionary) -> void:
	_drops.append(item_data)


func _on_pocket(_origin: Vector2i, _size: Vector2i, _duration: float) -> void:
	_pockets += 1


func _on_pocket_created(_pocket_id: int, _rect: Rect2i, _duration: float) -> void:
	_pockets += 1


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
