class_name PaperFactory extends Building

const WOOD_ITEM := "res://pickups/wood.tres"
const PAPER_ITEM := "res://pickups/paper.tres"
const BAR_WIDTH := 36.0
const PAPER_OUTPUT_OFFSET := Vector2(80, 0)

@export var smoke_consume_amt: int = 3
@export var wood_consume_amt: int = 1
@export var stored_wood: int = 0
@export var stored_wood_cap: int = 5
@export var deposit_range: float = 64.0
@export var cycle_paid: bool = false

func _enter_tree() -> void:
	super._enter_tree()
	add_to_group("paper_factories")

func _ready() -> void:
	super._ready()
	if animation_player and animation_player.has_animation("paper"):
		var paper_anim: Animation = animation_player.get_animation("paper")
		if paper_anim:
			paper_anim.loop_mode = Animation.LOOP_LINEAR

func try_deposit_wood(player_id: int) -> bool:
	if not multiplayer.is_server():
		return false
	if is_ghost or destroyed or not is_operating():
		return false
	if stored_wood >= stored_wood_cap:
		return false
	var player_node: Node = PlayerManager.get_player_node_by_id(player_id)
	if player_node == null or not (player_node is Node2D):
		return false
	if (player_node as Node2D).global_position.distance_to(factory_origin()) > deposit_range:
		return false
	if not PlayerManager.has_resources(player_id, WOOD_ITEM, 1):
		return false
	var was_producing: bool = is_producing_paper()
	PlayerManager.consume_resources(player_id, WOOD_ITEM, 1)
	stored_wood += 1
	if not was_producing:
		timer = 0.0
	return true

func in_interact_range(player: Node2D) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	if not is_operating():
		return false
	return player.global_position.distance_to(factory_origin()) <= deposit_range

func can_prompt_deposit(player: Node2D) -> bool:
	if not in_interact_range(player):
		return false
	if stored_wood >= stored_wood_cap:
		return false
	var player_id: int = 0
	if player.has_method("get_multiplayer_authority"):
		player_id = int(player.get_multiplayer_authority())
	if player_id <= 0 and player.name.is_valid_int():
		player_id = int(player.name)
	return PlayerManager.carried_count(player_id, WOOD_ITEM) >= 1

func needs_wood() -> bool:
	if not is_operating():
		return false
	return stored_wood < wood_consume_amt

func is_producing_paper() -> bool:
	if not is_operating():
		return false
	if stored_wood < wood_consume_amt:
		return false
	if cycle_paid:
		return true
	return PlayerManager.smoke_amt >= smoke_consume_amt

func production_progress() -> float:
	if interval <= 0.0:
		return 0.0
	return clampf(timer / interval, 0.0, 1.0)

func status_bar_fill_width() -> float:
	var hud: Node = get_node_or_null("/root/FactoryStatusHud")
	if hud and hud.has_method("bar_fill_width"):
		return float(hud.bar_fill_width(self))
	return BAR_WIDTH * production_progress()

func paper_output_position() -> Vector2:
	return factory_origin() + PAPER_OUTPUT_OFFSET

func _emit_paper() -> void:
	SignalBus.on_item_drop.emit({
		"item_type": PAPER_ITEM,
		"position": paper_output_position(),
	})

func _try_begin_cycle() -> bool:
	if cycle_paid:
		return true
	if not is_operating():
		return false
	if stored_wood < wood_consume_amt:
		return false
	if PlayerManager.smoke_amt < smoke_consume_amt:
		return false
	if not PlayerManager.use_smoke(smoke_consume_amt):
		return false
	cycle_paid = true
	timer = 0.0
	return true

func _complete_cycle() -> void:
	if not cycle_paid:
		return
	cycle_paid = false
	timer = 0.0
	if not is_operating():
		return
	if stored_wood < wood_consume_amt:
		return
	stored_wood -= wood_consume_amt
	_emit_paper()

func _sync_work_animation() -> void:
	if animation_player == null:
		return
	if is_producing_paper():
		if animation_player.current_animation != "paper":
			animation_player.play("paper")
	elif animation_player.current_animation == "paper":
		animation_player.play("RESET")

func _process(delta: float) -> void:
	if not is_operating():
		_sync_work_animation()
		return
	if multiplayer.is_server():
		sync_blizzard_interval()
		if not cycle_paid:
			_try_begin_cycle()
		if not is_operating():
			_sync_work_animation()
			return
		if cycle_paid:
			timer += delta
			if timer >= interval:
				timer = 0.0
				_complete_cycle()
		else:
			timer = 0.0
	_sync_work_animation()
