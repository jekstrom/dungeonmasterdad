class_name Player extends CharacterBody2D

const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO
var invulnerable: bool = false
var hitpoints: int = 6
var max_hp: int = 6

@onready var camera_2d: PlayerCamera = $Camera2D
@onready var label: Label = $Label

var current_building_data: BuildingData
var ghost_building: Node2D

@export var sync_name: String:
	set(val):
		sync_name = val
		var name_label = get_node_or_null("Label")
		if name_label:
			name_label.text = val
			
@export var sync_color: Color:
	set(val):
		sync_color = val
		var name_label = get_node_or_null("Label")
		if name_label:
			name_label.self_modulate = val
			
@onready var state_machine: PlayerStateMachine = $PlayerStateMachine
signal DirectionChanged(new_direction: Vector2)

func _enter_tree() -> void:
	var id: int = name.to_int()
	print("mp id: " + str(id))
	set_multiplayer_authority(name.to_int())

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
func _ready() -> void:
	if is_multiplayer_authority():
		camera_2d.make_current()
	else:
		camera_2d.enabled = false
		
	state_machine.Initialize(self)
	SignalBus.build_smoke_building_pressed.connect(setup_building)

	await get_tree().process_frame
	if not multiplayer.is_server() and is_multiplayer_authority():
		request_name_fix.rpc_id(1)
	label.text = sync_name
	label.self_modulate = sync_color
	
@rpc("any_peer", "reliable")
func request_name_fix():
	if not multiplayer.is_server(): return
	update_client_name.rpc(sync_name, sync_color)
	
@rpc("any_peer", "reliable")
func update_client_name(n, c):
	sync_name = n
	sync_color = c
	
func _process(_delta: float) -> void:
	if !is_multiplayer_authority(): return
	if current_building_data:
		var mouse_pos = get_global_mouse_position()
		var snapped_pos = (mouse_pos / 32).floor() * 32
		snapped_pos.x += 16
		snapped_pos.y += 16
		update_ghost(snapped_pos)

func setup_building():
	current_building_data = load("res://buildings/buildables/SmokeFactory.tres")
	if ghost_building:
		remove_child(ghost_building)
		ghost_building = null
	ghost_building = current_building_data.scene.instantiate()
	ghost_building.name = "ghost"
	var collision = ghost_building.get_node_or_null("CollisionShape2D")
	if collision:
		collision.disabled = true
	
	add_child(ghost_building)
	ghost_building.set_ghost()
	
func update_ghost(pos):
	var valid_placement = BuildingManager.is_area_clear(pos, Vector2(BuildingData.building_size, BuildingData.building_size))
	if !valid_placement:
		ghost_building.modulate = Color(1, 0, 0, 0.7)
	else:
		ghost_building.modulate = Color(0, 1, 0, 0.7)
	ghost_building.global_position = pos

func _physics_process(_delta: float) -> void:
	if !is_multiplayer_authority(): return
	
	direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()
	velocity = direction * 300
	move_and_slide()

func update_animation(state: String) -> void:
	animation_player.play(state + "_" + anim_direction())

func anim_direction() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	return "side"

func set_direction() -> bool:
	if direction == Vector2.ZERO:
		return false
	
	var direction_id: int = int(round((direction + cardinal_direction * 0.1).angle() / TAU * DIR_4.size()))
	var new_dir = DIR_4[direction_id]
	
	if new_dir == cardinal_direction:
		return false
	
	cardinal_direction = new_dir
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	
	DirectionChanged.emit(new_dir)
	
	return true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("primary_click"):
		if current_building_data:
			# Request server to place the building
			print("request placement for ", current_building_data.resource_path)
			BuildingManager.request_placement.rpc_id(1, current_building_data.resource_path, ghost_building.global_position)
			remove_child(ghost_building)
			current_building_data = null
			ghost_building = null
