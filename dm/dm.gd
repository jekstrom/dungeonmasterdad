class_name DM extends CharacterBody2D

const AbilityCatalog = preload("res://dm/dm_ability_catalog.gd")
const DewSlickScript = preload("res://doodads/dew_slick.gd")
const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO
var invulnerable: bool = false

var hitpoints: int = 100
var max_hp: int = 100
const RESPAWN_DELAY_SEC: float = 10.0
var _dead: bool = false
var _respawn_remaining: float = 0.0

const BlizzardIceDrawScript = preload("res://spells/blizzard/blizzard_ice_draw.gd")

# US-059: one sheet per state (512×384, hframes=4 vframes=3). No PlayerSprite02 fallback.
const SHEET_IDLE := "res://dm/sprites/dm_idle.png"
const SHEET_WALK := "res://dm/sprites/dm_walk.png"
const SHEET_ATTACK := "res://dm/sprites/dm_attack.png"
const SHEET_CAST := "res://dm/sprites/dm_cast.png"
## Visual scale for wizard sheets (~half prior on-screen size; root stays 1.2).
const SPRITE_SCALE: float = 0.5

const STATE_SHEETS := {
	"idle": SHEET_IDLE,
	"walk": SHEET_WALK,
	"attack": SHEET_ATTACK,
	"cast": SHEET_CAST,
}

@export var targeting_scene: PackedScene
@export var fireball_spell: PackedScene
var current_targeting: Node
var _targeting_spell_id: String = ""

@onready var camera_2d: DmCamera = $Camera2D

@onready var state_machine: DmStateMachine = $DmStateMachine
signal DirectionChanged(new_direction: Vector2)


@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var label: Label = $Label
@onready var hitbox: Hitbox = $Hitbox
@onready var attack_hurtbox: Hurtbox = $AttackHurtbox

@export var melee_damage: int = 1

func _ready() -> void:
	z_index = DungeonConstants.WALL_Z_INDEX
	y_sort_enabled = false
	_apply_state_sheet("idle")
	_apply_sprite_scale()
	collision_mask = collision_mask | 16
	if is_multiplayer_authority():
		camera_2d.make_current()
	else:
		camera_2d.enabled = false
		
	DmManager.dm = self
	state_machine.Initialize(self)
	label.text = DmManager.dm_player_name
	SignalBus.start_spell_cast.connect(setup_targeting)
	if multiplayer.is_server():
		DmManager.broadcast_health(hitpoints, max_hp)

func setup_targeting(spell_id: String):
	if _dead:
		return
	print("targeting for ", spell_id)
	_targeting_spell_id = spell_id
	if current_targeting:
		remove_child(current_targeting)
		current_targeting = null
	current_targeting = targeting_scene.instantiate()
	current_targeting.name = "reticle"
	current_targeting.modulate = Color.RED
	var collision = current_targeting.get_node_or_null("CollisionShape2D")
	if collision:
		collision.disabled = true
	if spell_id == AbilityCatalog.BEMIDJI_BLIZZARD:
		_size_blizzard_reticle(current_targeting)
		current_targeting.modulate = Color.WHITE
	add_child(current_targeting)
	set_direction()
	update_animation("cast")

func _blizzard_aim_origin(world: Vector2) -> Vector2i:
	var size: Vector2i = DmManager.BLIZZARD_POCKET_CELLS
	var cell: Vector2i = DungeonGrid.from_world(world)
	return cell - Vector2i(int(size.x / 2), int(size.y / 2))

func _size_blizzard_reticle(reticle: Node) -> void:
	var size: Vector2i = DmManager.BLIZZARD_POCKET_CELLS
	var world_size: Vector2 = Vector2(size) * DungeonGrid.CELL_PX
	var reticle_sprite: Sprite2D = reticle.get_node_or_null("Sprite2D") as Sprite2D
	if reticle_sprite:
		reticle_sprite.visible = false
	BlizzardIceDrawScript.attach_grid(reticle, -world_size * 0.5, size, 2)

func update_target(pos):
	if current_targeting == null:
		return
	if _targeting_spell_id == AbilityCatalog.BEMIDJI_BLIZZARD:
		current_targeting.set_meta("blizzard_origin", _blizzard_aim_origin(pos))
	current_targeting.global_position = pos

func _process(delta: float) -> void:
	if _dead:
		_tick_respawn(delta)
		return
	if !is_multiplayer_authority(): return
	if current_targeting:
		update_target(get_global_mouse_position())
		var facing_changed := set_direction()
		var anim := str(animation_player.current_animation) if animation_player else ""
		if facing_changed or not anim.begins_with("cast"):
			update_animation("cast")
func _physics_process(delta: float) -> void:
	if _dead:
		velocity = Vector2.ZERO
		return
	if !is_multiplayer_authority(): return
	if state_machine.current_state and state_machine.current_state.name == "attack":
		velocity = Vector2.ZERO
		move_and_slide()
		enforce_map_interior()
		return
	
	direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()
	var desired: Vector2 = direction * DmManager.dm_move_speed()
	if DewSlickScript.any_covers_world(global_position):
		velocity = DewSlickScript.slide_velocity(velocity, desired, delta)
	else:
		velocity = desired
	move_and_slide()
	enforce_map_interior()

func enforce_map_interior() -> void:
	var level: Node = get_tree().get_first_node_in_group("level_manager") if get_tree() else null
	if level and level.has_method("enforce_body_interior"):
		level.enforce_body_interior(self)

func apply_knockback(from: Vector2, distance: float) -> void:
	if _dead:
		return
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	_apply_knockback_local(from, distance)

func _apply_knockback_local(from: Vector2, distance: float) -> void:
	if _dead:
		return
	var dir: Vector2 = global_position - from
	if dir.length() < 0.001:
		dir = Vector2.DOWN
	else:
		dir = dir.normalized()
	var dist: float = maxf(0.0, distance)
	global_position += dir * dist
	velocity = dir * (dist / 0.5)
	enforce_map_interior()

@rpc("any_peer", "reliable")
func apply_interior_clamp(pos: Vector2) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != 1:
		return
	if not is_multiplayer_authority():
		return
	global_position = pos
	velocity = Vector2.ZERO

func wants_melee_attack(event: InputEvent) -> bool:
	if _dead:
		return false
	if current_targeting:
		return false
	if event.is_action_pressed("primary_click"):
		return true
	if event.is_action_pressed("fire"):
		return true
	if event.is_action_pressed("attack"):
		return true
	return false

func is_downed() -> bool:
	return _dead

static func cardinal_from_aim(aim: Vector2, current: Vector2 = Vector2.DOWN) -> Vector2:
	if aim.length() < 8.0:
		return current
	var biased: Vector2 = aim.normalized() + current * 0.1
	var direction_id: int = posmod(int(round(biased.angle() / TAU * float(DIR_4.size()))), DIR_4.size())
	return DIR_4[direction_id]

func apply_aim(aim: Vector2) -> bool:
	var new_dir: Vector2 = cardinal_from_aim(aim, cardinal_direction)
	if new_dir == cardinal_direction:
		return false
	cardinal_direction = new_dir
	if sprite:
		sprite.scale = Vector2(-SPRITE_SCALE if cardinal_direction == Vector2.LEFT else SPRITE_SCALE, SPRITE_SCALE)
	DirectionChanged.emit(new_dir)
	return true

func set_direction() -> bool:
	if not is_inside_tree():
		return false
	return apply_aim(get_global_mouse_position() - global_position)

func start_melee_attack() -> void:
	var facing: Vector2 = cardinal_direction
	if multiplayer.is_server():
		_pulse_melee_hurtbox(facing)
	else:
		request_melee_attack.rpc_id(1, facing)

func end_melee_attack() -> void:
	if attack_hurtbox:
		attack_hurtbox.monitoring = false

@rpc("any_peer", "reliable")
func request_melee_attack(facing: Vector2) -> void:
	if not multiplayer.is_server():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != get_multiplayer_authority():
		return
	_pulse_melee_hurtbox(facing)

func _pulse_melee_hurtbox(facing: Vector2) -> void:
	if attack_hurtbox == null:
		return
	attack_hurtbox.damage = melee_damage
	attack_hurtbox.position = Vector2(facing.x * 20.0, facing.y * 16.0 - 8.0)
	attack_hurtbox.monitoring = false
	attack_hurtbox.monitoring = true
	var tree := get_tree()
	if tree:
		tree.create_timer(0.12).timeout.connect(func() -> void:
			if is_instance_valid(attack_hurtbox):
				attack_hurtbox.monitoring = false
		)

func update_animation(state: String) -> void:
	# While a spell reticle is live, body stays on cast_* (d20) except melee is already blocked.
	if current_targeting != null and state != "attack" and state != "cast":
		state = "cast"
	# Walk facings follow movement; idle/attack/cast keep aim (cardinal_direction).
	if state == "walk":
		_sync_facing_from_move()
	_apply_state_sheet(state)
	if animation_player == null:
		return
	var anim := state + "_" + anim_direction()
	# Only (re)start when the clip name changes — never restart every frame.
	if animation_player.current_animation != anim or not animation_player.is_playing():
		animation_player.play(anim)


func _apply_sprite_scale() -> void:
	if sprite == null:
		return
	var sx: float = -SPRITE_SCALE if cardinal_direction == Vector2.LEFT else SPRITE_SCALE
	sprite.scale = Vector2(sx, SPRITE_SCALE)


func _apply_state_sheet(state: String) -> void:
	if sprite == null:
		return
	var path: String = str(STATE_SHEETS.get(state, SHEET_IDLE))
	var tex := load(path) as Texture2D
	if tex == null:
		push_error("US-059: missing DM wizard sheet %s (no PlayerSprite02 fallback)" % path)
		return
	# Always assign — reference compare can miss and leave walk sheet on idle.
	sprite.texture = tex
	sprite.hframes = 4
	sprite.vframes = 3


## Prefer dominant movement axis so walk_down/up/side actually swap while moving.
func _sync_facing_from_move() -> bool:
	if direction.length() < 0.01:
		return false
	var new_dir: Vector2
	if absf(direction.x) >= absf(direction.y):
		new_dir = Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	else:
		new_dir = Vector2.DOWN if direction.y > 0.0 else Vector2.UP
	if new_dir == cardinal_direction:
		return false
	cardinal_direction = new_dir
	if sprite:
		sprite.scale = Vector2(-SPRITE_SCALE if cardinal_direction == Vector2.LEFT else SPRITE_SCALE, SPRITE_SCALE)
	DirectionChanged.emit(new_dir)
	return true


func anim_direction() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	return "side"



func apply_fantasy_hit(amount: int) -> void:
	if not multiplayer.is_server():
		return
	if _dead or invulnerable:
		return
	invulnerable = true
	var tree := get_tree()
	if tree:
		tree.create_timer(0.6).timeout.connect(_clear_invulnerable)
	else:
		_clear_invulnerable()
	var dmg: int = maxi(1, amount)
	if int(DmManager.fantasy_level) > 0:
		DmManager.update_fantasy_level(-dmg)
		return
	hitpoints = maxi(0, hitpoints - dmg)
	DmManager.broadcast_health(hitpoints, max_hp)
	if hitpoints <= 0:
		_begin_death()


func _clear_invulnerable() -> void:
	if _dead:
		invulnerable = true
		return
	invulnerable = false


func _begin_death() -> void:
	if _dead:
		return
	play_death.rpc()


@rpc("authority", "call_local", "reliable")
func play_death() -> void:
	_dead = true
	invulnerable = true
	velocity = Vector2.ZERO
	_respawn_remaining = RESPAWN_DELAY_SEC
	_clear_targeting()
	_set_body_present(false)
	DmManager.notify_respawn_countdown(_respawn_remaining)


func _tick_respawn(delta: float) -> void:
	if _respawn_remaining <= 0.0:
		return
	_respawn_remaining = maxf(0.0, _respawn_remaining - delta)
	DmManager.notify_respawn_countdown(_respawn_remaining)
	if _respawn_remaining > 0.0:
		return
	if multiplayer.is_server():
		finish_respawn.rpc(_entrance_spawn_position())


func _entrance_spawn_position() -> Vector2:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager and manager.has_method("get_entrance_world_position"):
		var from_layout: Vector2 = manager.call("get_entrance_world_position")
		if from_layout.is_finite():
			return from_layout
	var tree := get_tree()
	if tree:
		var portal: Node = tree.get_first_node_in_group("entrance")
		if portal is Node2D:
			return (portal as Node2D).global_position
	return global_position


@rpc("authority", "call_local", "reliable")
func finish_respawn(spawn_position: Vector2) -> void:
	if spawn_position.is_finite():
		global_position = spawn_position
	hitpoints = max_hp
	_dead = false
	_respawn_remaining = 0.0
	invulnerable = false
	velocity = Vector2.ZERO
	_set_body_present(true)
	DmManager.broadcast_health(hitpoints, max_hp)
	DmManager.notify_respawn_countdown(-1.0)


func _set_body_present(present: bool) -> void:
	if sprite:
		sprite.visible = present
	if label:
		label.visible = present
	var collision := get_node_or_null("CollisionShape2D")
	if collision is CollisionShape2D:
		(collision as CollisionShape2D).set_deferred("disabled", not present)
	if hitbox:
		hitbox.set_deferred("monitorable", present)
		hitbox.set_deferred("monitoring", present)
	if attack_hurtbox:
		attack_hurtbox.monitoring = false


func play_audio(_stream: AudioStream) -> void:
	print("playing audio")
	audio_stream_player_2d.stream = _stream
	audio_stream_player_2d.play()
	
func confirm_targeted_spell() -> void:
	if _dead:
		return
	if current_targeting == null:
		return
	var spell_id: String = _targeting_spell_id
	var target: Vector2 = current_targeting.global_position
	var spell_data := {
		"shooter_id": multiplayer.get_unique_id(),
		"position": Vector2(global_position.x, global_position.y - 16),
		"target": target,
		"radius_bonus": 0,
		"radius": DmManager.fireball_radius(),
		"base_damage_bonus": 0,
		"speed_bonus": 0,
	}
	if spell_id == AbilityCatalog.BEMIDJI_BLIZZARD:
		var size: Vector2i = DmManager.BLIZZARD_POCKET_CELLS
		var origin: Vector2i = _blizzard_aim_origin(target)
		if current_targeting.has_meta("blizzard_origin"):
			origin = current_targeting.get_meta("blizzard_origin")
		spell_data["origin"] = origin
		spell_data["size"] = size
		spell_data["duration"] = DmManager.blizzard_duration()
		spell_data["slow_factor"] = DmManager.BLIZZARD_SLOW_FACTOR
	_clear_targeting()
	_targeting_spell_id = ""
	if spell_id == AbilityCatalog.BEMIDJI_BLIZZARD:
		DmManager.request_launch_blizzard(spell_data)
		return
	if not multiplayer.is_server():
		return
	DmManager.launch_fireball(spell_data)

func _clear_targeting() -> void:
	if current_targeting == null:
		return
	if current_targeting.get_parent() == self:
		remove_child(current_targeting)
	current_targeting.queue_free()
	current_targeting = null
	_targeting_spell_id = ""
	# US-059: leave cast sheet — resume staff idle/walk.
	if direction != Vector2.ZERO:
		update_animation("walk")
	else:
		update_animation("idle")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("primary_click") and current_targeting:
		if is_multiplayer_authority() or multiplayer.is_server():
			confirm_targeted_spell()
		var viewport := get_viewport()
		if viewport:
			viewport.set_input_as_handled()
		
