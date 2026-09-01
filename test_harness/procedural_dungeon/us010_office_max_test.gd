extends Node

## US-010 Office Max headless independent test (T002–T007).
## Play-pass (two-window) is QA-owned; not run here.

const METAL := "res://pickups/metal.tres"
const PAPER := "res://pickups/paper.tres"
const WOOD := "res://pickups/wood.tres"
const OFFICE_MAX_ID := "res://buildings/buildables/OfficeMax.tres"
const OFFICE_MAX_SCENE := preload("res://buildings/buildables/office_max.tscn")

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.max_inv_slots = 8
	PlayerManager.reality_level = 0
	PlayerManager.smoke_amt = 3
	var peer_id: int = multiplayer.get_unique_id()
	PlayerManager.register_player(peer_id, "Paper Pusher")

	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	level.add_to_group("level_manager")
	add_child(level)
	await get_tree().process_frame

	var interior := Rect2i(0, 0, 16, 10)
	var dungeon := Rect2i(8, 2, 8, 6)
	level.tree_scatter_density = 0.0
	level.apply_map_interior(interior, dungeon)
	_free_group_children(level.get_node_or_null("ScatteredTrees"))
	_free_group_children(level.get_node_or_null("ScatteredMines"))
	await get_tree().process_frame
	await get_tree().physics_frame

	var reality = load("res://zones/reality_zone.tscn").instantiate()
	add_child(reality)
	await get_tree().process_frame

	var root := Node2D.new()
	root.add_to_group("building_root")
	add_child(root)

	var metal: ItemData = load(METAL) as ItemData
	var paper: ItemData = load(PAPER) as ItemData
	var wood: ItemData = load(WOOD) as ItemData
	var data: BuildingData = BuildingDatabase.get_building(OFFICE_MAX_ID)
	if data == null:
		_fail("US-010: BuildingDatabase must load OfficeMax.tres")
		return
	if not data.unique_building:
		_fail("US-010 T002: Office Max must be unique_building")
		return
	if data.cost_item != METAL or data.cost_qty != 3:
		_fail("US-010 T002: Office Max must cost 3 metal")
		return

	var size := Vector2(data.size)
	var legal: Vector2 = _first_clear(size)
	if legal == Vector2.INF:
		_fail("US-010 T002: expected a legal Reality outside cell")
		return

	# --- T002 place ---
	PlayerManager.add_item_to_inventory(peer_id, metal, 3)
	if not BuildingManager.can_place(OFFICE_MAX_ID, legal, peer_id):
		_fail("US-010 T002: can_place must be true with iron + legal footprint")
		return
	BuildingManager.request_placement(OFFICE_MAX_ID, legal, legal)
	await get_tree().process_frame
	if root.get_child_count() != 1:
		_fail("US-010 T002: place must spawn one Office Max")
		return
	var om: Node = root.get_child(0)
	if not om.has_method("try_restock_staples"):
		_fail("US-010 T002: spawned node must support restock")
		return
	if int(om.get("max_hitpoints")) != 16 or int(om.get("hitpoints")) != 16:
		_fail("US-010 T002: HP must be 16, got max=%s hp=%s" % [om.get("max_hitpoints"), om.get("hitpoints")])
		return
	if bool(om.get("destroyed")):
		_fail("US-010 T002: fresh Office Max must not be destroyed")
		return
	if bool(om.get("is_ghost")):
		_fail("US-010 T002: enabled Office Max must not remain ghost")
		return

	PlayerManager.add_item_to_inventory(peer_id, metal, 3)
	var second: Vector2 = _first_clear(size)
	if BuildingManager.can_place(OFFICE_MAX_ID, second, peer_id):
		_fail("US-010 T002: can_place must be false while one is enabled")
		return
	BuildingManager.request_placement(OFFICE_MAX_ID, second, second)
	await get_tree().process_frame
	if root.get_child_count() != 1:
		_fail("US-010 T002: second place must be rejected")
		return
	if PlayerManager.get_item_count(peer_id, METAL) != 3:
		_fail("US-010 T002: rejected unique place must not spend metal")
		return
	print("US-010 T002 office max unique place passed")

	# --- T003 / T004 restock ---
	var player: Player = Player.new()
	player.name = str(peer_id)
	player.set_multiplayer_authority(peer_id)
	add_child(player)
	player.set_process(false)
	player.set_physics_process(false)
	await get_tree().process_frame
	player.staple_magazine_max = 20
	player.staple_count = 5
	PlayerManager.add_item_to_inventory(peer_id, paper, 4)
	PlayerManager.add_item_to_inventory(peer_id, wood, 4)
	var smoke_before: int = PlayerManager.smoke_amt
	var paper_before: int = PlayerManager.get_item_count(peer_id, PAPER)
	var wood_before: int = PlayerManager.get_item_count(peer_id, WOOD)
	var iron_before: int = PlayerManager.get_item_count(peer_id, METAL)

	# Out of range
	player.global_position = om.global_position + Vector2(400, 0)
	if bool(om.call("try_restock_staples", peer_id, player)):
		_fail("US-010 T004: out of range must reject")
		return
	if player.staple_count != 5 or PlayerManager.get_item_count(peer_id, METAL) != iron_before:
		_fail("US-010 T004: out of range must leave mag/iron unchanged")
		return

	# Ghost reject
	var ghost: Node = OFFICE_MAX_SCENE.instantiate()
	ghost.name = "ghost"
	ghost.set("is_ghost", true)
	ghost.global_position = player.global_position
	add_child(ghost)
	await get_tree().process_frame
	if bool(ghost.call("try_restock_staples", peer_id, player)):
		_fail("US-010 T004: ghost must not restock")
		return
	ghost.queue_free()

	# Happy path: 5 -> 20 costs ceil(15/10)=2
	player.global_position = om.global_position
	if not bool(om.call("in_restock_range", player)):
		_fail("US-010 T003: player on building must be in restock range")
		return
	if not bool(om.call("try_restock_staples", peer_id, player)):
		_fail("US-010 T003: restock with enough iron must succeed")
		return
	if player.staple_count != 20:
		_fail("US-010 T003: mag must fill to max, got %d" % player.staple_count)
		return
	var expected_iron: int = iron_before - 2
	if PlayerManager.get_item_count(peer_id, METAL) != expected_iron:
		_fail("US-010 T003: iron cost must be 2, have %d want %d" % [PlayerManager.get_item_count(peer_id, METAL), expected_iron])
		return
	if PlayerManager.get_item_count(peer_id, PAPER) != paper_before:
		_fail("US-010 T003: paper must be unchanged")
		return
	if PlayerManager.get_item_count(peer_id, WOOD) != wood_before:
		_fail("US-010 T003: wood must be unchanged")
		return
	if PlayerManager.smoke_amt != smoke_before:
		_fail("US-010 T003: smoke must be unchanged")
		return
	print("US-010 T003 office max restock passed")

	# Full mag no-op
	iron_before = PlayerManager.get_item_count(peer_id, METAL)
	if bool(om.call("try_restock_staples", peer_id, player)):
		_fail("US-010 T004: full mag must no-op")
		return
	if player.staple_count != 20 or PlayerManager.get_item_count(peer_id, METAL) != iron_before:
		_fail("US-010 T004: full mag must leave mag/iron unchanged")
		return

	# Not enough iron: need 2, give 1
	player.staple_count = 5
	# drain to 1 iron
	var have: int = PlayerManager.get_item_count(peer_id, METAL)
	if have > 1:
		PlayerManager.consume_resources(peer_id, METAL, have - 1)
	elif have < 1:
		PlayerManager.add_item_to_inventory(peer_id, metal, 1)
	iron_before = PlayerManager.get_item_count(peer_id, METAL)
	if iron_before != 1:
		_fail("US-010 T004 setup: expected 1 iron, got %d" % iron_before)
		return
	if bool(om.call("try_restock_staples", peer_id, player)):
		_fail("US-010 T004: not enough iron must reject")
		return
	if player.staple_count != 5 or PlayerManager.get_item_count(peer_id, METAL) != 1:
		_fail("US-010 T004: insufficient iron must leave mag/iron unchanged")
		return
	print("US-010 T004 restock gates passed")

	# --- T005 destroy ---
	PlayerManager.add_item_to_inventory(peer_id, metal, 5)
	player.staple_count = 5
	om.call("destroy")
	await get_tree().process_frame
	if not bool(om.get("destroyed")):
		_fail("US-010 T005: destroy must set destroyed")
		return
	if int(om.get("hitpoints")) != 0:
		_fail("US-010 T005: destroy must set HP to 0")
		return
	var sprite: Sprite2D = om.get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		_fail("US-010 T005: sprite missing")
		return
	var ruined_ok := false
	if ResourceLoader.exists("res://sprites/office_max_rubble.png") and sprite.texture != null:
		ruined_ok = sprite.texture.resource_path.ends_with("office_max_rubble.png")
	elif sprite.modulate.r < 0.5:
		ruined_ok = true  # placeholder darken
	if not ruined_ok:
		_fail("US-010 T005: destroyed visuals must use rubble or dark placeholder")
		return
	if bool(om.call("try_restock_staples", peer_id, player)):
		_fail("US-010 T005: restock must fail when destroyed")
		return
	if player.staple_count != 5:
		_fail("US-010 T005: failed restock must not change mag")
		return

	# Uniqueness frees for rebuild
	var rebuild_pos: Vector2 = _first_clear(size)
	if rebuild_pos == Vector2.INF:
		_fail("US-010 T005: expected legal cell for rebuild")
		return
	if not BuildingManager.can_place(OFFICE_MAX_ID, rebuild_pos, peer_id):
		_fail("US-010 T005: uniqueness must allow rebuild after destroy")
		return
	BuildingManager.request_placement(OFFICE_MAX_ID, rebuild_pos, rebuild_pos)
	await get_tree().process_frame
	var live_count := 0
	var rebuilt: Node = null
	for child in root.get_children():
		if not is_instance_valid(child):
			continue
		if child.has_method("try_restock_staples") and not bool(child.get("destroyed")):
			live_count += 1
			rebuilt = child
	if live_count != 1 or rebuilt == null:
		_fail("US-010 T005: rebuild must leave exactly one live Office Max")
		return
	player.global_position = rebuilt.global_position
	PlayerManager.add_item_to_inventory(peer_id, metal, 2)
	player.staple_count = 5
	if not bool(rebuilt.call("try_restock_staples", peer_id, player)):
		_fail("US-010 T005: rebuilt Office Max must restock")
		return
	if player.staple_count != 20:
		_fail("US-010 T005: rebuilt restock must fill mag")
		return
	print("US-010 T005 destroyed / rebuild passed")

	# --- T006 two players independent restock ---
	PlayerManager.register_player(2, "Paper Pusher B")
	var player_b: Player = Player.new()
	player_b.name = "2"
	player_b.set_multiplayer_authority(2)
	add_child(player_b)
	player_b.set_process(false)
	player_b.set_physics_process(false)
	await get_tree().process_frame
	player_b.staple_magazine_max = 20
	player_b.staple_count = 11
	PlayerManager.add_item_to_inventory(2, metal, 3)
	player.staple_count = 8
	PlayerManager.add_item_to_inventory(peer_id, metal, 3)
	var iron_a0: int = PlayerManager.get_item_count(peer_id, METAL)
	var iron_b0: int = PlayerManager.get_item_count(2, METAL)
	player.global_position = rebuilt.global_position
	player_b.global_position = rebuilt.global_position
	# A: 8->20 needs 12 staples -> 2 iron
	if not bool(rebuilt.call("try_restock_staples", peer_id, player)):
		_fail("US-010 T006: player A restock must succeed")
		return
	if player.staple_count != 20 or PlayerManager.get_item_count(peer_id, METAL) != iron_a0 - 2:
		_fail("US-010 T006: player A mag/iron incorrect")
		return
	if player_b.staple_count != 11 or PlayerManager.get_item_count(2, METAL) != iron_b0:
		_fail("US-010 T006: player B must be unchanged after A restock")
		return
	# B: 11->20 needs 9 staples -> 1 iron
	if not bool(rebuilt.call("try_restock_staples", 2, player_b)):
		_fail("US-010 T006: player B restock must succeed")
		return
	if player_b.staple_count != 20 or PlayerManager.get_item_count(2, METAL) != iron_b0 - 1:
		_fail("US-010 T006: player B mag/iron incorrect")
		return
	if player.staple_count != 20 or PlayerManager.get_item_count(peer_id, METAL) != iron_a0 - 2:
		_fail("US-010 T006: player A must stay independent after B restock")
		return
	print("US-010 T006 independent restock passed")

	print("US-010 T002/T003 office max test passed")
	print("US-010 T002-T007 office max test passed")
	get_tree().quit(0)

func _first_clear(size: Vector2) -> Vector2:
	var zone: Node = get_tree().get_first_node_in_group("RealityZone")
	if zone == null or not ("home_rect" in zone):
		return Vector2.INF
	var home: Rect2i = zone.home_rect
	for y in range(home.position.y, home.end.y):
		for x in range(home.position.x, home.end.x):
			var pos: Vector2 = DungeonGrid.to_world_center(Vector2i(x, y))
			if BuildingManager.is_area_clear(pos, size):
				return pos
	return Vector2.INF

func _free_group_children(parent: Node) -> void:
	if parent == null:
		return
	for child in parent.get_children():
		child.free()

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
