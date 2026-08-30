extends Node

const TAX := "res://pickups/tax_form.tres"
const FILLED := "res://pickups/filled_form.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.max_inv_slots = 8
	PlayerManager.reality_level = 0
	PlayerManager.tax_file_rl = 50
	PlayerManager.register_player(1, "Paper Pusher")
	var tax: ItemData = load(TAX) as ItemData
	PlayerManager.add_item_to_inventory(1, tax, 1)

	var player: Player = Player.new()
	player.name = "1"
	add_child(player)
	player.set_process(false)
	player.set_physics_process(false)
	await get_tree().process_frame

	if player._host_try_file_tax():
		_fail("US-009 T006: file must fail with no IRS")
		return
	if PlayerManager.get_item_count(1, TAX) != 1:
		_fail("US-009 T006: no IRS must leave the tax form")
		return
	if PlayerManager.reality_level != 0:
		_fail("US-009 T006: no IRS must not raise Reality")
		return

	var irs: IrsBuilding = load("res://buildings/buildables/irs.tscn").instantiate() as IrsBuilding
	irs.position = Vector2(80, 0)
	irs.is_ghost = false
	add_child(irs)
	irs.enable()
	await get_tree().process_frame
	player.position = Vector2(400, 0)
	if irs.try_file_tax(1):
		_fail("US-009 T006: out of range must fail")
		return

	player.position = irs.position
	if PlayerManager.tax_file_rl <= PlayerManager.PAPER_FACTORY_RL:
		_fail("US-009 T006: tax RL must beat a paper-factory cycle")
		return
	if not irs.try_file_tax(1):
		_fail("US-009 T006: in-range file must succeed")
		return
	if PlayerManager.get_item_count(1, TAX) != 0:
		_fail("US-009 T006: filing must consume the tax form")
		return
	if PlayerManager.reality_level != 50:
		_fail("US-009 T006: filing must grant +50 Reality, got %d" % PlayerManager.reality_level)
		return

	var filled: ItemData = load(FILLED) as ItemData
	PlayerManager.add_item_to_inventory(1, filled, 1)
	var rl: int = PlayerManager.reality_level
	if irs.try_file_tax(1):
		_fail("US-009 T006: standard form must not file")
		return
	if PlayerManager.reality_level != rl:
		_fail("US-009 T006: standard form must not raise Reality at IRS")
		return

	irs.is_ghost = true
	PlayerManager.add_item_to_inventory(1, tax, 1)
	if irs.try_file_tax(1):
		_fail("US-009 T006: ghost IRS must not file")
		return

	print("US-009 T006 file tax test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
