class_name DmIdleState extends DmState

const DewSlickScript = preload("res://doodads/dew_slick.gd")

@onready var walk: DmState = $"../walk"
@onready var attack: DmState = $"../attack"

func Enter() -> void:
	dm.update_animation("idle")
	
func Exit() -> void:
	pass

func Process(_delta: float) -> DmState:
	if dm.direction != Vector2.ZERO:
		return walk
	if not DewSlickScript.any_covers_world(dm.global_position):
		dm.velocity = Vector2.ZERO
	var facing_changed := dm.set_direction()
	var anim := ""
	if dm.animation_player:
		anim = str(dm.animation_player.current_animation)
	# Re-apply when facing changes or clip/sheet left walk/attack.
	if facing_changed or not anim.begins_with("idle"):
		dm.update_animation("idle")
	else:
		# Sheet can still be wrong if clip name matched — force idle texture.
		dm._apply_state_sheet("idle")
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
