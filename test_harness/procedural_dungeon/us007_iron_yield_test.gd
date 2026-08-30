extends Node

const METAL := "res://pickups/metal.tres"
const COAL := "res://pickups/coal.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.max_inv_slots = 8
	PlayerManager.register_player(1, "Paper Pusher")
	PlayerManager.register_player(2, "Paper Pusher 2")

	var mine: MineDoodad = _make_mine()
	mine.regen_cooldown = 0.0
	var player: Player = _make_player("1")
	await get_tree().process_frame
	for _i in range(3):
		mine.apply_harvest_hit(player)
	if PlayerManager.get_item_count(1, METAL) != 0:
		_fail("US-007 T004: incomplete cycle must not grant iron")
		return
	mine.apply_harvest_hit(player)
	if PlayerManager.get_item_count(1, METAL) != 1:
		_fail("US-007 T004: 4 hits must grant 1 metal, got %d" % PlayerManager.get_item_count(1, METAL))
		return
	if mine.is_depleted:
		_fail("US-007 T004: first yield must not deplete the mine")
		return
	if mine.hits_taken != 0:
		_fail("US-007 T004: hits_taken must reset after a yield")
		return

	for _y in range(4):
		for _h in range(4):
			mine.apply_harvest_hit(player)
	if not mine.is_depleted:
		_fail("US-007 T004: 5 yields must deplete the mine")
		return
	var metal_after: int = PlayerManager.get_item_count(1, METAL)
	if not (metal_after == 5):
		_fail("US-007 T004: five yields must grant 5 metal, got %d" % metal_after)
		return
	if mine.apply_harvest_hit(player):
		_fail("US-007 T004: depleted mine must refuse harvest")
		return
	if PlayerManager.get_item_count(1, METAL) != 5:
		_fail("US-007 T004: depleted mine must not grant more iron")
		return
	if mine.sprite_2d.texture != MineDoodad.DEPLETED_TEXTURE:
		_fail("US-007 T004: depleted mine must use mine_depleted.png")
		return
	mine._process(1.0)
	if not mine.is_depleted:
		_fail("US-007 T004: regen_cooldown 0 must stay depleted")
		return

	var drops: Array = []
	SignalBus.on_item_drop.connect(func(data: Dictionary) -> void:
		drops.append(data)
	)
	PlayerManager.players_data.clear()
	PlayerManager.max_inv_slots = 1
	PlayerManager.register_player(1, "Paper Pusher")
	var coal: ItemData = load(COAL) as ItemData
	PlayerManager.add_item_to_inventory(1, coal, 1)
	var drop_mine: MineDoodad = _make_mine()
	for _h in range(4):
		drop_mine.apply_harvest_hit(player)
	if PlayerManager.get_item_count(1, METAL) != 0:
		_fail("US-007 T004: full inventory without metal must not grant to inventory")
		return
	if drops.is_empty() or str(drops[0].get("item_type", "")) != METAL:
		_fail("US-007 T004: full inventory must drop metal as a world pickup")
		return

	var race: MineDoodad = _make_mine()
	for _h in range(3):
		race.apply_harvest_hit(player)
	PlayerManager.players_data.clear()
	PlayerManager.max_inv_slots = 8
	PlayerManager.register_player(1, "Paper Pusher")
	PlayerManager.register_player(2, "Paper Pusher 2")
	var p2: Player = _make_player("2")
	race.apply_harvest_hit(player)
	race.apply_harvest_hit(p2)
	var total: int = PlayerManager.get_item_count(1, METAL) + PlayerManager.get_item_count(2, METAL)
	if total != 1:
		_fail("US-007 T004: same-frame last hits must yield iron once, got %d" % total)
		return

	var regen: MineDoodad = _make_mine()
	regen.regen_cooldown = 0.05
	regen.yields_before_deplete = 1
	for _h in range(4):
		regen.apply_harvest_hit(player)
	if not regen.is_depleted:
		_fail("US-007 T004: expected depleted before regen")
		return
	regen._process(0.06)
	if regen.is_depleted:
		_fail("US-007 T004: regen_cooldown elapsed must restore the mine")
		return
	if not regen.apply_harvest_hit(player):
		_fail("US-007 T004: regenerated mine must be harvestable")
		return

	print("US-007 T004 iron yield test passed")
	get_tree().quit(0)

func _make_mine() -> MineDoodad:
	var mine: MineDoodad = load("res://doodads/mine.tscn").instantiate() as MineDoodad
	mine.regen_cooldown = 0.0
	add_child(mine)
	return mine

func _make_player(id_name: String) -> Player:
	var player: Player = Player.new()
	player.name = id_name
	return player

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
