extends Node

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.register_player(1, "Paper Pusher")
	PlayerManager.register_player(2, "Paper Pusher 2")

	var mine: MineDoodad = load("res://doodads/mine.tscn").instantiate() as MineDoodad
	add_child(mine)
	await get_tree().process_frame
	if mine.hits_required != 4:
		_fail("US-007 T003: default hits_required must be 4")
		return
	var player: Player = Player.new()
	player.name = "1"
	player.position = mine.global_position
	if not mine.apply_harvest_hit(player):
		_fail("US-007 T003: first melee must apply a harvest hit")
		return
	if mine.hits_taken != 1:
		_fail("US-007 T003: after 1 hit hits_taken must be 1, got %d" % mine.hits_taken)
		return
	FactoryStatusHud._process(0.0)
	if not FactoryStatusHud.mine_bar_visible(mine):
		_fail("US-007 T003: first hit must show the harvest progress bar")
		return
	if absf(FactoryStatusHud.mine_bar_fill_width(mine) - FactoryStatusHud.BAR_WIDTH * 0.25) > 0.2:
		_fail("US-007 T003: one hit must fill 25%% of the bar, width=%s" % FactoryStatusHud.mine_bar_fill_width(mine))
		return
	mine.apply_harvest_hit(player)
	mine.apply_harvest_hit(player)
	if mine.hits_taken != 3:
		_fail("US-007 T003: three hits must leave hits_taken 3")
		return
	FactoryStatusHud._process(0.0)
	if absf(FactoryStatusHud.mine_bar_fill_width(mine) - FactoryStatusHud.BAR_WIDTH * 0.75) > 0.2:
		_fail("US-007 T003: three hits must fill 75%% of the bar, width=%s" % FactoryStatusHud.mine_bar_fill_width(mine))
		return
	var p2: Player = Player.new()
	p2.name = "2"
	p2.position = mine.global_position
	if not mine.apply_harvest_hit(p2):
		_fail("US-007 T003: second player must share progress")
		return
	if mine.hits_taken != 0:
		_fail("US-007 T003: fourth shared hit completes a yield and resets hits, got %d" % mine.hits_taken)
		return
	FactoryStatusHud._process(0.0)
	if FactoryStatusHud.mine_bar_visible(mine):
		_fail("US-007 T003: completed yield must hide the harvest bar")
		return
	if not mine.is_harvest_prompt_target(player):
		_fail("US-007 T003: nearby active mine must prompt SPACE")
		return
	player.position = Vector2(400, 0)
	if mine.is_harvest_prompt_target(player):
		_fail("US-007 T003: far mine must not prompt harvest")
		return
	print("US-007 T003 mine harvest test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
