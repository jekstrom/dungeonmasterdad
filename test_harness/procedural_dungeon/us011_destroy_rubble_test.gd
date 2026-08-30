extends Node

const WOOD_PATH := "res://pickups/wood.tres"
const PAPER_PATH := "res://pickups/paper.tres"
const IRS_ID := "res://buildings/buildables/Irs.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.smoke_amt = 3
	PlayerManager.reality_level = 0
	PlayerManager.register_player(1, "Paper Pusher")

	var goblin: Enemy = load("res://monsters/goblin.tscn").instantiate() as Enemy
	add_child(goblin)
	await get_tree().process_frame
	var hurtbox: Hurtbox = goblin.get_node("Hurtbox") as Hurtbox

	var smoke: SmokeFactory = load("res://buildings/buildables/smoke_factory.tscn").instantiate() as SmokeFactory
	add_child(smoke)
	await get_tree().process_frame
	smoke.enable()
	smoke.is_ghost = false
	smoke.set_process(false)
	var smoke_before: int = PlayerManager.smoke_amt
	smoke.hitpoints = 1
	smoke.take_damage(hurtbox)
	if not smoke.destroyed:
		_fail("US-011 T004: last HP must destroy the smoke factory")
		return
	if smoke.is_operating():
		_fail("US-011 T004: destroyed smoke factory must not operate")
		return
	if smoke.collision_shape_2d and not smoke.collision_shape_2d.disabled:
		_fail("US-011 T004: destroyed factory collision must be disabled")
		return
	var smoke_sprite: Sprite2D = smoke.get_node("Sprite2D") as Sprite2D
	if smoke_sprite == null or smoke_sprite.texture == null or smoke_sprite.texture.resource_path.find("smoke_factory_rubble") < 0:
		_fail("US-011 T004: smoke factory must swap to rubble texture")
		return
	smoke._process(smoke.interval)
	if PlayerManager.smoke_amt != smoke_before:
		_fail("US-011 T004: destroyed smoke factory must not add smoke")
		return

	var drops: Array = []
	SignalBus.on_item_drop.connect(func(data: Dictionary) -> void:
		drops.append(data)
	)
	var paper: PaperFactory = load("res://buildings/buildables/paper_factory.tscn").instantiate() as PaperFactory
	add_child(paper)
	await get_tree().process_frame
	paper.enable()
	paper.is_ghost = false
	paper.set_process(false)
	paper.stored_wood = 2
	paper.cycle_paid = true
	paper.timer = paper.interval
	var wood: ItemData = load(WOOD_PATH) as ItemData
	PlayerManager.add_item_to_inventory(1, wood, 2)
	var player := Node2D.new()
	player.name = "1"
	player.add_to_group("players")
	player.position = Vector2.ZERO
	add_child(player)
	paper.hitpoints = 1
	paper.take_damage(hurtbox)
	if not paper.destroyed:
		_fail("US-011 T004: last HP must destroy the paper factory")
		return
	var reality_before: int = PlayerManager.reality_level
	var smoke_mid: int = PlayerManager.smoke_amt
	paper._process(paper.interval)
	if PlayerManager.smoke_amt != smoke_mid:
		_fail("US-011 T004: destroy must not spend more smoke")
		return
	if PlayerManager.reality_level != reality_before:
		_fail("US-011 T004: destroy must not raise Reality")
		return
	for drop in drops:
		if str(drop.get("item_type", "")) == PAPER_PATH:
			_fail("US-011 T004: same-frame destroy must not emit paper")
			return
	var paper_sprite: Sprite2D = paper.get_node("Sprite2D") as Sprite2D
	if paper_sprite == null or paper_sprite.texture == null or paper_sprite.texture.resource_path.find("paper_factory_rubble") < 0:
		_fail("US-011 T004: paper factory must swap to rubble texture")
		return
	var wood_before: int = PlayerManager.get_item_count(1, WOOD_PATH)
	if paper.try_deposit_wood(1):
		_fail("US-011 T004: deposit after destroy must fail")
		return
	if PlayerManager.get_item_count(1, WOOD_PATH) != wood_before:
		_fail("US-011 T004: failed deposit must leave inventory wood")
		return

	var root := Node2D.new()
	root.add_to_group("building_root")
	add_child(root)
	var irs: IrsBuilding = load("res://buildings/buildables/irs.tscn").instantiate() as IrsBuilding
	root.add_child(irs)
	await get_tree().process_frame
	irs.enable()
	irs.is_ghost = false
	irs.take_damage(hurtbox)
	while irs.hitpoints > 0 and not irs.destroyed:
		irs.take_damage(hurtbox)
	if not irs.destroyed or irs.is_operating():
		_fail("US-011 T004: IRS must be destroyed and not operating")
		return
	if irs.is_fileable():
		_fail("US-011 T004: destroyed IRS must not be fileable")
		return
	var irs_sprite: Sprite2D = irs.get_node("Sprite2D") as Sprite2D
	if irs_sprite == null or irs_sprite.texture == null or irs_sprite.texture.resource_path.find("irs_building_rubble") < 0:
		_fail("US-011 T004: IRS must swap to rubble texture")
		return
	var data: BuildingData = BuildingDatabase.get_building(IRS_ID)
	if data == null:
		_fail("US-011 T004: Irs.tres must load")
		return
	if BuildingManager._has_enabled_unique(data):
		_fail("US-011 T004: destroyed IRS must free the unique slot")
		return

	print("US-011 T004 destroy rubble test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
