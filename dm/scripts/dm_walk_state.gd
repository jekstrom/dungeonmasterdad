class_name DmWalkState extends DmState

const DewSlickScript = preload("res://doodads/dew_slick.gd")

@export var move_speed: float = 100.0
@onready var idle: DmState = $"../idle"
@onready var attack: DmState = $"../attack"

func Enter() -> void:
	dm.update_animation("walk")
	
func Exit() -> void:
	pass

func Process(_delta: float) -> DmState:
	if dm.direction == Vector2.ZERO:
		return idle
	if not DewSlickScript.any_covers_world(dm.global_position):
		dm.velocity = dm.direction * DmManager.dm_move_speed()
	# Mouse aim still updates for attack/cast; walk clip facing comes from move.
	dm.set_direction()
	var move_facing_changed := dm._sync_facing_from_move()
	var anim := ""
	if dm.animation_player:
		anim = str(dm.animation_player.current_animation)
	if move_facing_changed or not anim.begins_with("walk"):
		dm.update_animation("walk")
	else:
		dm._apply_state_sheet("walk")
	return null
	
func Physics(_delta: float) -> DmState:
	return null
	
func HandleInput(_event: InputEvent) -> DmState:
	if !is_multiplayer_authority():
		return null
	if dm.wants_melee_attack(_event):
		return attack
	if _event.is_action_pressed("interact"):
		DmManager.interact_pressed.emit()
	for i in 4:
		if _event.is_action_pressed("inv_slot_%d" % i):
			PlayerManager.use_instant_slot(dm.get_multiplayer_authority(), i)
			break
	return null
