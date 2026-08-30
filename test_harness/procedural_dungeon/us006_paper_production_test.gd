extends Node

const PAPER_PATH := "res://pickups/paper.tres"

func _ready() -> void:
	PlayerManager.smoke_amt = 5
	PlayerManager.reality_level = 0
	var drops: Array = []
	SignalBus.on_item_drop.connect(func(data: Dictionary) -> void:
		drops.append(data)
	)

	var factory: PaperFactory = load("res://buildings/buildables/paper_factory.tscn").instantiate() as PaperFactory
	add_child(factory)
	factory.enable()
	factory.is_ghost = false
	factory.set_process(false)
	factory.stored_wood = 0
	factory.timer = 0.0
	await get_tree().process_frame
	if not is_equal_approx(factory.interval, 6.0):
		_fail("US-006 T006: paper factory interval must be 6s (3x previous 2s), got %s" % factory.interval)
		return
	factory.is_ghost = true
	factory.collision_shape_2d.disabled = false
	if not factory.needs_wood():
		_fail("US-006 T006: client replica with live collision must still need wood")
		return
	factory.is_ghost = false
	FactoryStatusHud._process(0.0)
	if not FactoryStatusHud.wood_visible(factory):
		_fail("US-006 T006: factory needing wood must show pulsing wood icon")
		return
	if FactoryStatusHud.paper_visible(factory):
		_fail("US-006 T006: wood-needed factory must not show paper progress")
		return

	var smoke_before: int = PlayerManager.smoke_amt
	var reality_before: int = PlayerManager.reality_level
	factory._process(factory.interval)
	if PlayerManager.smoke_amt != smoke_before:
		_fail("US-006 T006: missing wood must not consume smoke")
		return
	if PlayerManager.reality_level != reality_before:
		_fail("US-006 T006: missing wood must not raise Reality")
		return
	if not drops.is_empty():
		_fail("US-006 T006: missing wood must not emit paper")
		return

	factory.timer = factory.interval * 0.95
	factory.stored_wood = 1
	PlayerManager.smoke_amt = 2
	factory._process(0.2)
	if factory.stored_wood != 1:
		_fail("US-006 T006: missing smoke must not spend wood")
		return
	if not is_equal_approx(factory.timer, 0.0):
		_fail("US-006 T006: idle factory timer must reset to 0, got %s" % factory.timer)
		return
	if not drops.is_empty():
		_fail("US-006 T006: missing smoke must not emit paper")
		return

	PlayerManager.smoke_amt = 5
	factory.timer = factory.interval * 0.9
	factory.stored_wood = 0
	factory._process(0.01)
	if not is_equal_approx(factory.timer, 0.0):
		_fail("US-006 T006: timer must clear while not producing, got %s" % factory.timer)
		return
	factory.stored_wood = 1
	factory._process(0.05)
	if factory.stored_wood != 1:
		_fail("US-006 T006: production must start at 0, not finish from leftover timer")
		return
	if PlayerManager.smoke_amt != 2:
		_fail("US-006 T006: smoke must be consumed when production begins, got %d" % PlayerManager.smoke_amt)
		return
	if not factory.cycle_paid:
		_fail("US-006 T006: beginning production must mark the smoke cycle paid")
		return
	if factory.timer < 0.04 or factory.timer > 0.2:
		_fail("US-006 T006: newly started production timer should be a small elapsed, got %s" % factory.timer)
		return
	PlayerManager.smoke_amt = 0
	if not factory.is_producing_paper():
		_fail("US-006 T006: paid cycle must continue even if smoke is later empty")
		return
	FactoryStatusHud._process(0.0)
	if not FactoryStatusHud.buffer_visible(factory) or FactoryStatusHud.buffer_count_text(factory) != "1":
		_fail("US-006 T006: buffered wood must show a count, got '%s'" % FactoryStatusHud.buffer_count_text(factory))
		return
	if FactoryStatusHud.wood_visible(factory):
		_fail("US-006 T006: pulsing need-wood icon must hide while buffer has wood")
		return

	PlayerManager.reality_level = 0
	factory.timer = factory.interval * 0.4
	factory._sync_work_animation()
	FactoryStatusHud._process(0.0)
	if FactoryStatusHud.wood_visible(factory):
		_fail("US-006 T006: producing factory must hide the wood-need icon")
		return
	if not FactoryStatusHud.paper_visible(factory):
		_fail("US-006 T006: producing factory must show paper icon and progress bar")
		return
	if absf(FactoryStatusHud.bar_fill_width(factory) - FactoryStatusHud.BAR_WIDTH * 0.4) > 0.2:
		_fail("US-006 T006: progress bar must match timer/interval, width=%s" % FactoryStatusHud.bar_fill_width(factory))
		return
	if factory.animation_player.current_animation != "paper":
		_fail("US-006 T006: working factory must play the paper animation")
		return
	var smoke_mid_cycle: int = PlayerManager.smoke_amt
	factory._process(factory.interval)
	if factory.stored_wood != 0:
		_fail("US-006 T006: success must consume wood, stored=%d" % factory.stored_wood)
		return
	if PlayerManager.smoke_amt != smoke_mid_cycle:
		_fail("US-006 T006: finishing must not consume smoke again, got %d" % PlayerManager.smoke_amt)
		return
	if PlayerManager.reality_level != 10:
		_fail("US-006 T006: success must raise Reality by 10, got %d" % PlayerManager.reality_level)
		return
	if drops.is_empty() or str(drops[0].get("item_type", "")) != PAPER_PATH:
		_fail("US-006 T006: success must drop paper at the factory")
		return
	var drop_pos: Vector2 = drops[0].get("position", Vector2.ZERO)
	if drop_pos.x <= factory.factory_origin().x + 8.0:
		_fail("US-006 T006: paper must drop to the right of the factory, got %s" % drop_pos)
		return
	if factory.animation_player.current_animation == "paper":
		_fail("US-006 T006: paper animation must stop after production")
		return

	print("US-006 T006 paper production test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
