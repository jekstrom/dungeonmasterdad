class_name Player extends CharacterBody2D

const DewSlickScript = preload("res://doodads/dew_slick.gd")
const FormFillChoiceScript = preload("res://gui/player/form_fill_choice.gd")
const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
const BASE_MOVE_SPEED: float = 300.0
var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO
var prev_direction: Vector2 = Vector2.ZERO
var invulnerable: bool = false
var stun_remaining: float = 0.0
@export var max_hp: int = 6
@export var hitpoints: int = 6:
	set(value):
		hitpoints = clampi(value, 0, maxi(1, max_hp) if max_hp > 0 else maxi(0, value))
		_refresh_health_bar()

@onready var camera_2d: PlayerCamera = get_node_or_null("Camera2D")
@onready var label: Label = get_node_or_null("Label")

var current_building_data: BuildingData
var ghost_building: Node2D
var _suppress_primary_staple_click: bool = false

@export var num_shadows: int = 0
@export var shadow_scene: PackedScene

@onready var hitbox: Hitbox = get_node_or_null("Hitbox")
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var attack_hurtbox: Hurtbox = get_node_or_null("AttackHurtbox")

@export var melee_damage: int = 1
@export var staple_magazine_max: int = 20
@export var staple_damage: int = 1
@export var staple_speed: float = 520.0
@export var staple_max_range: float = 360.0
var staple_count: int = 20
var empty_click_played: bool = false
var _melee_swing_active: bool = false
var _melee_pulse_id: int = 0
var _queued_staple_fire: bool = false
var _hint_space: Label
var _filling: bool = false
var _fill_duration_sync: float = 0.0
var _fill_type: String = ""
var _fill_elapsed: float = 0.0
var _fill_token: int = 0
var _fill_origin: Vector2 = Vector2.ZERO
var _fill_slot_index: int = 0
var _fill_held: bool = false
var _fill_require_hold: bool = false
var _form_choice: CanvasLayer
var _form_choice_slot: int = -1
@export var fill_move_cancel_px: float = 4.0
@export var standard_fill_sec: float = 3.0
@export var tax_fill_sec: float = 6.0

const TEX_STAPLE_GUN: Texture2D = preload("res://player/sprites/player_staple_gun.png")
const TEX_PENCIL_MELEE: Texture2D = preload("res://player/sprites/player_pencil_melee.png")
const TEX_INK_SLASH: Texture2D = preload("res://sprites/melee_ink_slash.png")
const TEX_SWORD_FALLBACK: Texture2D = preload("res://player/sprites/PlayerSprite02.png")

signal staple_count_changed(count: int)

const HEALTH_BAR_SCENE: PackedScene = preload("res://monsters/enemy_health_bar.tscn")
var _health_bar: Node2D

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
			
@onready var state_machine: PlayerStateMachine = get_node_or_null("PlayerStateMachine")
signal DirectionChanged(new_direction: Vector2)

func _enter_tree() -> void:
	var id: int = name.to_int()
	print("player id: " + str(id))
	# Only set authority if multiplayer is ready and we have a valid ID
	if multiplayer.has_multiplayer_peer() and id > 0:
		set_multiplayer_authority(id)
	add_to_group("players")
	# 16 = walls/cliffs. Clear bit 32 so a leftover Fantasy exclusion shape cannot block Paper Pushers (US-003 T011).
	collision_mask = (collision_mask | 16) & ~32

func _ready() -> void:
	z_index = DungeonConstants.WALL_Z_INDEX
	y_sort_enabled = false
	if camera_2d:
		if is_multiplayer_authority():
			camera_2d.make_current()
		else:
			camera_2d.enabled = false
		
	_ensure_combat_visuals()
	_spawn_health_bar()
	_configure_hp_replication()
	if state_machine:
		state_machine.Initialize(self)
	staple_count = staple_magazine_max
	_refresh_staple_hud()
	if is_multiplayer_authority():
		_ensure_interact_hints()
	SignalBus.build_smoke_building_pressed.connect(setup_building)
	SignalBus.build_paper_building_pressed.connect(setup_building)
	if not SignalBus.build_irs_building_pressed.is_connected(setup_building):
		SignalBus.build_irs_building_pressed.connect(setup_building)
	if not SignalBus.build_office_max_building_pressed.is_connected(setup_building):
		SignalBus.build_office_max_building_pressed.connect(setup_building)
	SignalBus.on_dm_unlock.connect(dm_unlock_listener)
	SignalBus.on_dm_lock.connect(dm_lock_listener)

	await get_tree().process_frame
	if not multiplayer.is_server() and is_multiplayer_authority():
		request_name_fix.rpc_id(1)
	if label:
		label.text = sync_name
		label.self_modulate = sync_color
	
	# Connect to death system signals for respawn handling
	SignalBus.player_respawn_completed.connect(_on_player_respawn_completed)
	if hitbox and not hitbox.Damaged.is_connected(take_damage):
		hitbox.Damaged.connect(take_damage)
	
func dm_unlock_listener(unlock_name: String) -> void:
	if unlock_name == "shadow_zone" and DmUnlocks.dm_unlocks.get("shadow_zone"):
		state_machine.RequestChangeStateTo.rpc_id(1, "snake")
	elif unlock_name == "shadow_zone" and !DmUnlocks.dm_unlocks.get("shadow_zone"):
		state_machine.ChangeStateTo("idle")
	
func dm_lock_listener(unlock_name: String) -> void:
	if unlock_name == "shadow_zone" and !DmUnlocks.dm_unlocks.get("shadow_zone"):
		state_machine.RequestChangeStateTo.rpc_id(1, "idle")
		
# Force player to idle state (used for respawn)
func force_idle_state() -> void:
	if state_machine and state_machine.has_method("ChangeStateTo"):
		state_machine.ChangeStateTo("idle")
		
# Force player to snake state (used for respawn)
func force_snake_state() -> void:
	if state_machine and state_machine.has_method("ChangeStateTo"):
		state_machine.RequestChangeStateTo.rpc_id(1, "snake")
		
@rpc("any_peer", "reliable")
func request_name_fix():
	if not multiplayer.is_server(): return
	update_client_name.rpc(sync_name, sync_color)
	
@rpc("any_peer", "reliable")
func update_client_name(n, c):
	sync_name = n
	sync_color = c
	
func _process(_delta: float) -> void:
	if multiplayer.is_server():
		tick_fill(_delta)
	elif _filling:
		_fill_elapsed += _delta
	if !is_multiplayer_authority():
		if _hint_space:
			_hint_space.visible = false
		return
	_update_interact_hints()
	if current_building_data:
		update_ghost(get_global_mouse_position())
		queue_redraw()

func setup_building(building: String):
	var path := "res://buildings/buildables/" + building + ".tres"
	current_building_data = load(path) as BuildingData
	if current_building_data == null:
		push_error("setup_building failed to load BuildingData: %s" % path)
		return
	_clear_ghost_building()
	ghost_building = current_building_data.scene.instantiate()
	_prepare_ghost_building(ghost_building)
	add_child(ghost_building)
	if ghost_building.has_method("set_ghost"):
		ghost_building.set_ghost()

func _prepare_ghost_building(node: Node) -> void:
	node.name = "ghost"
	node.set_scene_file_path("")
	var sync := node.get_node_or_null("MultiplayerSynchronizer")
	if sync:
		node.remove_child(sync)
		sync.free()
	var collision := node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision:
		collision.disabled = true
	if node is CollisionObject2D:
		(node as CollisionObject2D).collision_layer = 0
		(node as CollisionObject2D).collision_mask = 0

func _clear_ghost_building() -> void:
	if ghost_building == null:
		return
	var ghost: Node = ghost_building
	ghost_building = null
	if is_instance_valid(ghost):
		if ghost.get_parent() == self:
			remove_child(ghost)
		ghost.queue_free()
	
func update_ghost(pos: Vector2):
	if ghost_building == null or current_building_data == null:
		return
	var origin: Vector2 = BuildingManager.placement_origin(pos)
	ghost_building.global_position = origin
	var valid_placement: bool = BuildingManager.can_place(current_building_data.resource_path, origin, _inventory_id())
	if valid_placement:
		ghost_building.modulate = Color(0, 1, 0, 0.7)
	else:
		ghost_building.modulate = Color(1, 0, 0, 0.7)

func is_stunned() -> bool:
	return stun_remaining > 0.0

func begin_trap_stun(duration: float = 3.0) -> void:
	stun_remaining = maxf(stun_remaining, maxf(0.0, duration))
	velocity = Vector2.ZERO
	direction = Vector2.ZERO
	cancel_fill()

func apply_trap_stun(duration: float = 3.0) -> void:
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	begin_trap_stun(duration)
	var owner_id: int = get_multiplayer_authority()
	if multiplayer.multiplayer_peer != null and owner_id != multiplayer.get_unique_id():
		begin_trap_stun_rpc.rpc_id(owner_id, duration)

@rpc("any_peer", "reliable")
func begin_trap_stun_rpc(duration: float) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	begin_trap_stun(duration)

func _physics_process(_delta: float) -> void:
	if stun_remaining > 0.0:
		stun_remaining = maxf(0.0, stun_remaining - _delta)
	if !is_multiplayer_authority(): return
	if state_machine == null or state_machine.current_state == null: return
	var state_name: String = state_machine.current_state.name
	if state_name == "death":
		_queued_staple_fire = false
		enforce_map_interior()
		return
	if is_stunned():
		direction = Vector2.ZERO
		velocity = Vector2.ZERO
		move_and_slide()
		enforce_map_interior()
		return
	
	if direction != Vector2.ZERO:
		prev_direction = direction
	direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()
	
	if state_name == "snake":
		_queued_staple_fire = false
		enforce_map_interior()
		return
	if state_name == "attack":
		velocity = Vector2.ZERO
		move_and_slide()
		enforce_map_interior()
		_flush_queued_staple_fire()
		_melee_swing_active = false
		return
	var desired: Vector2 = direction * get_move_speed()
	if DewSlickScript.any_covers_world(global_position):
		velocity = DewSlickScript.slide_velocity(velocity, desired, _delta)
	else:
		velocity = desired
	move_and_slide()
	enforce_map_interior()
	_flush_queued_staple_fire()
	_melee_swing_active = false

func blizzard_slow_factor() -> float:
	return DmManager.blizzard_slow_factor_at(global_position)

func get_move_speed() -> float:
	if is_stunned():
		return 0.0
	return BASE_MOVE_SPEED * blizzard_slow_factor()

func enforce_map_interior() -> void:
	var level: Node = get_tree().get_first_node_in_group("level_manager") if get_tree() else null
	if level and level.has_method("enforce_body_interior"):
		level.enforce_body_interior(self)

func apply_knockback(from: Vector2, distance: float) -> void:
	if is_stunned():
		return
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	if is_multiplayer_authority() or not multiplayer.has_multiplayer_peer():
		_apply_knockback_local(from, distance)
		return
	receive_knockback.rpc_id(get_multiplayer_authority(), from, distance)

@rpc("authority", "reliable")
func receive_knockback(from: Vector2, distance: float) -> void:
	_apply_knockback_local(from, distance)

func _apply_knockback_local(from: Vector2, distance: float) -> void:
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
	if not event.is_action_pressed("attack"):
		return false
	if is_combat_locked():
		return false
	return true

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
		# Dedicated left/right frames live on the office sheets; do not mirror the sword sheet.
		sprite.scale = Vector2.ONE
	DirectionChanged.emit(new_dir)
	return true

func set_direction() -> bool:
	if not is_inside_tree():
		return false
	return apply_aim(get_global_mouse_position() - global_position)

func set_direction_from_vector(vec: Vector2) -> bool:
	return apply_aim(vec)

func handle_form_input(event: InputEvent) -> void:
	if event.is_action_pressed("create_form"):
		try_create_form()
		return
	for i in 4:
		var action := "inv_slot_%d" % i
		if event.is_action_pressed(action):
			try_use_active_slot(i)
			return
		if event.is_action_released(action):
			if _filling and _fill_require_hold and _fill_slot_index == i:
				if multiplayer.is_server():
					cancel_fill()
				else:
					request_cancel_fill.rpc_id(1)
			return

func try_interact() -> void:
	if multiplayer.is_server():
		_host_try_interact()
	else:
		request_interact.rpc_id(1)

@rpc("any_peer", "reliable")
func request_interact() -> void:
	if not multiplayer.is_server():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != get_multiplayer_authority():
		return
	_host_try_interact()

func _host_try_interact() -> void:
	if _host_try_restock_office_max():
		return
	if _host_try_file_tax():
		return
	_host_try_deposit_wood()

func _host_try_restock_office_max() -> bool:
	var player_id: int = _inventory_id()
	var nearest: Node = null
	var best := INF
	for node in _office_max_nodes():
		if not node.has_method("try_restock_staples"):
			continue
		if node.has_method("is_restockable") and not bool(node.is_restockable()):
			continue
		if node.has_method("in_restock_range") and not bool(node.in_restock_range(self)):
			continue
		var dist: float = _office_max_distance(node)
		if dist < best:
			best = dist
			nearest = node
	if nearest == null:
		return false
	return bool(nearest.try_restock_staples(player_id, self))

func _office_max_nodes() -> Array:
	var out: Array = []
	var scene_tree := get_tree()
	if scene_tree == null:
		return out
	for node in scene_tree.get_nodes_in_group("office_max"):
		if is_instance_valid(node) and not out.has(node):
			out.append(node)
	var root: Node = scene_tree.get_first_node_in_group("building_root")
	if root == null:
		return out
	for child in root.get_children():
		if not is_instance_valid(child):
			continue
		var scene_path := str(child.scene_file_path)
		if child.has_method("try_restock_staples") or scene_path.ends_with("office_max.tscn"):
			if not out.has(child):
				out.append(child)
	return out

func _office_max_distance(node: Node) -> float:
	var from: Vector2 = global_position
	var best: float = from.distance_to(node.global_position)
	if node.has_method("factory_origin"):
		best = minf(best, from.distance_to(node.factory_origin()))
	var sprite: Sprite2D = node.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		best = minf(best, from.distance_to(sprite.global_position))
	return best

func _host_try_file_tax() -> bool:
	var player_id: int = _inventory_id()
	var nearest: Node = null
	var best := INF
	for node in _irs_nodes():
		if not node.has_method("try_file_tax"):
			continue
		if node.has_method("is_fileable") and not bool(node.is_fileable()):
			continue
		if node.has_method("in_file_range") and not bool(node.in_file_range(self)):
			continue
		var dist: float = _irs_distance(node)
		if dist < best:
			best = dist
			nearest = node
	if nearest == null:
		return false
	return bool(nearest.try_file_tax(player_id, self))

func _irs_nodes() -> Array:
	var out: Array = []
	var scene_tree := get_tree()
	if scene_tree == null:
		return out
	for node in scene_tree.get_nodes_in_group("irs"):
		if is_instance_valid(node) and not out.has(node):
			out.append(node)
	var root: Node = scene_tree.get_first_node_in_group("building_root")
	if root == null:
		return out
	for child in root.get_children():
		if not is_instance_valid(child):
			continue
		var scene_path := str(child.scene_file_path)
		if child.has_method("try_file_tax") or scene_path.ends_with("irs.tscn"):
			if not out.has(child):
				out.append(child)
	return out

func _irs_distance(node: Node) -> float:
	var from: Vector2 = global_position
	var best: float = from.distance_to(node.global_position)
	if node.has_method("factory_origin"):
		best = minf(best, from.distance_to(node.factory_origin()))
	var i_sprite: Sprite2D = node.get_node_or_null("Sprite2D") as Sprite2D
	if i_sprite:
		best = minf(best, from.distance_to(i_sprite.global_position))
	return best

func _inventory_id() -> int:
	var player_id: int = get_multiplayer_authority()
	if player_id <= 0 and name.is_valid_int():
		player_id = int(name)
	return player_id

func try_create_form() -> void:
	if is_combat_locked():
		return
	if multiplayer.is_server():
		PlayerManager.create_form(_inventory_id())
	else:
		request_create_form.rpc_id(1)

@rpc("any_peer", "reliable")
func request_create_form() -> void:
	if not multiplayer.is_server():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != get_multiplayer_authority():
		return
	if is_combat_locked():
		return
	PlayerManager.create_form(_inventory_id())

func try_use_active_slot(index: int) -> void:
	if is_combat_locked():
		return
	if _form_choice != null:
		return
	var item := _item_in_active_slot(index)
	if item != null and item.channel_use:
		_open_form_fill_choice(index)
		return
	if multiplayer.is_server():
		use_active_slot(index)
		return
	request_use_active_slot.rpc_id(1, index, "", true)

func _item_in_active_slot(index: int) -> ItemData:
	var slots: Array = PlayerManager.local_slots
	if slots.is_empty():
		slots = PlayerManager.get_slots(_inventory_id())
	if index < 0 or index >= slots.size():
		return null
	var entry: Dictionary = slots[index] if typeof(slots[index]) == TYPE_DICTIONARY else {}
	var path := str(entry.get("path", ""))
	if path.is_empty() or int(entry.get("qty", 0)) <= 0:
		return null
	var item: ItemData = ItemDatabase.get_item(path)
	if item == null:
		item = load(path) as ItemData
	return item

func _open_form_fill_choice(index: int) -> void:
	if _form_choice != null:
		return
	_form_choice_slot = index
	_form_choice = FormFillChoiceScript.new()
	_form_choice.connect("chosen", _on_form_fill_chosen)
	if PlayerHud:
		PlayerHud.add_child(_form_choice)
	elif is_inside_tree():
		get_tree().root.add_child(_form_choice)
	else:
		_form_choice = null

func _on_form_fill_chosen(kind: String) -> void:
	var slot: int = _form_choice_slot
	_close_form_fill_choice()
	if kind != "standard" and kind != "tax":
		return
	if is_combat_locked():
		return
	if _is_host():
		use_active_slot(slot, kind, false)
	else:
		_predict_channel_use(slot, kind, false)
		request_use_active_slot.rpc_id(1, slot, kind, false)

func _close_form_fill_choice() -> void:
	if _form_choice != null and is_instance_valid(_form_choice):
		_form_choice.queue_free()
	_form_choice = null
	_form_choice_slot = -1

func _predict_channel_use(index: int, fill_kind: String, require_hold: bool = true) -> void:
	var slots: Array = PlayerManager.local_slots
	if index < 0 or index >= slots.size():
		return
	var entry: Dictionary = slots[index] if typeof(slots[index]) == TYPE_DICTIONARY else {}
	var path := str(entry.get("path", ""))
	if path.is_empty():
		return
	var item: ItemData = ItemDatabase.get_item(path)
	if item == null or not item.channel_use:
		return
	_filling = true
	_fill_type = fill_kind if fill_kind == "tax" or fill_kind == "standard" else "standard"
	_fill_elapsed = 0.0
	_fill_duration_sync = tax_fill_sec if _fill_type == "tax" else standard_fill_sec
	_fill_require_hold = require_hold
	_fill_slot_index = index
	_fill_held = not require_hold

func _fill_kind_from_input() -> String:
	return "standard"

@rpc("any_peer", "reliable")
func request_use_active_slot(index: int, fill_kind: String = "standard", require_hold: bool = true) -> void:
	if not multiplayer.is_server():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != get_multiplayer_authority():
		return
	use_active_slot(index, fill_kind, require_hold)

@rpc("any_peer", "reliable")
func request_cancel_fill() -> void:
	if not multiplayer.is_server():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != get_multiplayer_authority():
		return
	cancel_fill()

func use_active_slot(index: int, fill_kind: String = "", require_hold: bool = true) -> bool:
	if not _is_host():
		return false
	if index < 0 or index >= 4:
		return false
	if is_combat_locked():
		return false
	var player_id: int = _inventory_id()
	var slots: Array = PlayerManager.get_slots(player_id)
	if index >= slots.size():
		return false
	var entry: Dictionary = slots[index] if typeof(slots[index]) == TYPE_DICTIONARY else {}
	var path := str(entry.get("path", ""))
	var qty := int(entry.get("qty", 0))
	if path.is_empty() or qty <= 0:
		return false
	var item: ItemData = ItemDatabase.get_item(path)
	if item == null:
		item = load(path) as ItemData
	if item == null:
		return false
	if item.channel_use:
		_fill_slot_index = index
		_fill_require_hold = require_hold
		_fill_held = not require_hold
		var kind := fill_kind
		if kind != "standard" and kind != "tax":
			kind = "standard"
		return begin_fill(kind)
	if path == PlayerManager.PAPER_ITEM:
		return PlayerManager.create_form(player_id)
	if path == PlayerManager.TAX_FORM_ITEM or (item != null and item.name == "Tax Form"):
		return _host_try_file_tax()
	if item.use():
		PlayerManager.consume_resources(player_id, path, 1)
		return true
	return true

func try_begin_fill(fill_type: String) -> void:
	_fill_require_hold = false
	if multiplayer.is_server():
		begin_fill(fill_type)
	else:
		request_begin_fill.rpc_id(1, fill_type)

@rpc("any_peer", "reliable")
func request_begin_fill(fill_type: String) -> void:
	if not multiplayer.is_server():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != get_multiplayer_authority():
		return
	begin_fill(fill_type)

func _is_host() -> bool:
	if not is_inside_tree() or multiplayer == null:
		return true
	return multiplayer.is_server()

func begin_fill(fill_type: String) -> bool:
	if not _is_host():
		return false
	if is_combat_locked():
		return false
	if _filling:
		return false
	if fill_type != "standard" and fill_type != "tax":
		return false
	var player_id: int = _inventory_id()
	if not PlayerManager.has_resources(player_id, PlayerManager.BLANK_FORM_ITEM, 1):
		return false
	_filling = true
	_fill_type = fill_type
	_fill_elapsed = 0.0
	_fill_duration_sync = tax_fill_sec if fill_type == "tax" else standard_fill_sec
	_fill_token += 1
	_fill_origin = global_position
	if not _fill_require_hold:
		_fill_held = true
	_broadcast_fill_state()
	return true

func cancel_fill() -> void:
	if not _filling:
		return
	_filling = false
	_fill_elapsed = 0.0
	_fill_type = ""
	_fill_duration_sync = 0.0
	_fill_held = false
	_fill_require_hold = false
	_broadcast_fill_state()

func tick_fill(delta: float) -> void:
	if not _is_host():
		return
	if not _filling:
		return
	if is_combat_locked():
		cancel_fill()
		return
	if global_position.distance_to(_fill_origin) > fill_move_cancel_px:
		cancel_fill()
		return
	if _fill_require_hold and not _fill_held:
		cancel_fill()
		return
	_fill_elapsed += delta
	if _fill_elapsed + 0.0001 >= _fill_duration():
		_complete_fill(_fill_token)

func _fill_duration() -> float:
	if _fill_duration_sync > 0.0:
		return _fill_duration_sync
	if _fill_type == "tax":
		return tax_fill_sec
	return standard_fill_sec

func fill_progress() -> float:
	var dur: float = _fill_duration()
	if dur <= 0.0:
		return 1.0
	return clampf(_fill_elapsed / dur, 0.0, 1.0)

func is_filling() -> bool:
	return _filling

func _complete_fill(token: int) -> void:
	if not _is_host():
		return
	if token != _fill_token:
		return
	if not _filling:
		return
	var kind: String = _fill_type
	_filling = false
	_fill_elapsed = 0.0
	_fill_type = ""
	_fill_duration_sync = 0.0
	_fill_held = false
	_fill_require_hold = false
	var player_id: int = _inventory_id()
	if not PlayerManager.has_resources(player_id, PlayerManager.BLANK_FORM_ITEM, 1):
		_broadcast_fill_state()
		return
	var out_path: String = PlayerManager.FILLED_FORM_ITEM
	if kind == "tax":
		out_path = PlayerManager.TAX_FORM_ITEM
	var out_item: ItemData = ItemDatabase.get_item(out_path)
	if out_item == null:
		out_item = load(out_path) as ItemData
	if out_item == null:
		_broadcast_fill_state()
		return
	PlayerManager.consume_resources(player_id, PlayerManager.BLANK_FORM_ITEM, 1)
	PlayerManager.grant_item_or_drop(player_id, out_item, 1, global_position)
	if kind == "standard":
		PlayerManager.update_reality_level(PlayerManager.standard_form_rl)
	_broadcast_fill_state()

func _broadcast_fill_state() -> void:
	if not is_inside_tree() or not _is_host():
		return
	var dur: float = _fill_duration() if _filling else 1.0
	_sync_fill_state.rpc(_filling, _fill_type, _fill_elapsed, dur, _fill_require_hold, _fill_slot_index)

@rpc("any_peer", "call_remote", "reliable")
func _sync_fill_state(filling: bool, fill_type: String, elapsed: float, duration: float, require_hold: bool = false, slot_index: int = 0) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != 1:
		return
	_filling = filling
	_fill_type = fill_type
	_fill_elapsed = elapsed
	_fill_duration_sync = duration if filling else 0.0
	_fill_require_hold = require_hold and filling
	_fill_slot_index = slot_index
	if filling:
		_fill_held = true

func _host_try_deposit_wood() -> void:
	var player_id: int = get_multiplayer_authority()
	if player_id <= 0 and name.is_valid_int():
		player_id = int(name)
	var nearest: PaperFactory = null
	var best := INF
	var scene_tree := get_tree()
	if scene_tree == null:
		return
	for node in scene_tree.get_nodes_in_group("factories"):
		if not (node is PaperFactory):
			continue
		var factory: PaperFactory = node
		var dist: float = global_position.distance_to(factory.factory_origin())
		if dist < best:
			best = dist
			nearest = factory
	if nearest:
		nearest.try_deposit_wood(player_id)

func can_prompt_building_interact() -> bool:
	if is_combat_locked():
		return false
	var scene_tree := get_tree()
	if scene_tree == null:
		return false
	for node in scene_tree.get_nodes_in_group("paper_factories"):
		if node is PaperFactory and (node as PaperFactory).can_prompt_deposit(self):
			return true
	for node in _irs_nodes():
		if node.has_method("can_prompt_file") and bool(node.can_prompt_file(self)):
			return true
	for node in _office_max_nodes():
		if node.has_method("can_prompt_restock") and bool(node.can_prompt_restock(self)):
			return true
	return false

func can_prompt_tree_harvest() -> bool:
	if is_combat_locked():
		return false
	var scene_tree := get_tree()
	if scene_tree == null:
		return false
	for node in scene_tree.get_nodes_in_group("harvest_trees"):
		if node is TreeDoodad and (node as TreeDoodad).is_harvest_prompt_target(self):
			return true
	for node in scene_tree.get_nodes_in_group("mines"):
		if node.has_method("is_harvest_prompt_target") and node.is_harvest_prompt_target(self):
			return true
	for node in scene_tree.get_nodes_in_group("harvest_nodes"):
		if node is MineDoodad:
			continue
		if node.has_method("is_harvest_prompt_target") and node.is_harvest_prompt_target(self):
			return true
	return false

func _ensure_interact_hints() -> void:
	if _hint_space != null:
		return
	_hint_space = _make_hint_label("SPACE", Vector2(-32, -128), Vector2(64, 20))
	add_child(_hint_space)

func _make_hint_label(text: String, pos: Vector2, size: Vector2) -> Label:
	var hint := Label.new()
	hint.text = text
	hint.position = pos
	hint.size = size
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(1, 1, 0.75, 1))
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	hint.add_theme_constant_override("outline_size", 6)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.z_index = 32
	hint.visible = false
	return hint

func _update_interact_hints() -> void:
	if _hint_space == null:
		_ensure_interact_hints()
	_hint_space.visible = can_prompt_tree_harvest()

func start_melee_attack() -> void:
	if is_combat_locked():
		return
	var facing: Vector2 = cardinal_direction
	_melee_swing_active = true
	if multiplayer.is_server():
		_pulse_melee_hurtbox(facing)
	else:
		request_melee_attack.rpc_id(1, facing)

func end_melee_attack() -> void:
	_melee_swing_active = false
	if attack_hurtbox:
		attack_hurtbox.monitoring = false
	var slash := get_node_or_null("MeleeInkSlash") as Sprite2D
	if slash:
		slash.visible = false

@rpc("any_peer", "reliable")
func request_melee_attack(facing: Vector2) -> void:
	if not multiplayer.is_server():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != get_multiplayer_authority():
		return
	if is_combat_locked():
		return
	_melee_swing_active = true
	_pulse_melee_hurtbox(facing)

func _pulse_melee_hurtbox(facing: Vector2) -> void:
	if is_combat_locked():
		return
	if attack_hurtbox == null:
		return
	_melee_swing_active = true
	_melee_pulse_id += 1
	var pulse_id: int = _melee_pulse_id
	attack_hurtbox.damage = melee_damage
	attack_hurtbox.position = Vector2(facing.x * 20.0, facing.y * 16.0 - 8.0)
	attack_hurtbox.monitoring = false
	attack_hurtbox.monitoring = true
	var tree := get_tree()
	if tree:
		tree.create_timer(0.12).timeout.connect(func() -> void:
			if pulse_id != _melee_pulse_id:
				return
			_melee_swing_active = false
			if is_instance_valid(attack_hurtbox):
				attack_hurtbox.monitoring = false
		)

func update_animation(state: String) -> void:
	if sprite:
		sprite.scale = Vector2.ONE
		if state == "attack":
			sprite.texture = TEX_PENCIL_MELEE
		else:
			sprite.texture = TEX_STAPLE_GUN
	var anim_name: String = state + "_" + anim_direction()
	if animation_player == null:
		return
	# Do not restart the same clip; play() every physics tick flickers on replicas.
	if animation_player.has_animation(anim_name):
		if animation_player.current_animation != anim_name:
			animation_player.play(anim_name)
	elif animation_player.has_animation(state + "_side"):
		if animation_player.current_animation != state + "_side":
			animation_player.play(state + "_side")

func anim_direction() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	if cardinal_direction == Vector2.UP:
		return "up"
	if cardinal_direction == Vector2.LEFT:
		return "left"
	return "right"

func is_ranged_fire_playing() -> bool:
	if animation_player == null:
		return false
	return str(animation_player.current_animation).begins_with("fire_")

func play_ranged_fire_animation() -> void:
	if sprite:
		sprite.texture = TEX_STAPLE_GUN
		sprite.scale = Vector2.ONE
	var anim_name: String = "fire_" + anim_direction()
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func combat_sheet_path() -> String:
	if sprite and sprite.texture:
		return str(sprite.texture.resource_path)
	return ""



func is_combat_locked() -> bool:
	if is_stunned():
		return true
	if _form_choice != null and is_instance_valid(_form_choice):
		return true
	if current_building_data:
		return true
	var pid: int = get_multiplayer_authority()
	if pid > 0:
		if DeathSystem.active_death_timers.has(pid) or DeathSystem.respawn_reservations.has(pid):
			return true
	if TrailManager.shadow_mode_active:
		return true
	if state_machine and state_machine.current_state:
		var state_name: String = state_machine.current_state.name
		if state_name == "death" or state_name == "respawn_wait" or state_name == "snake":
			return true
	return false

func wants_fire_staple(event: InputEvent) -> bool:
	if is_combat_locked():
		return false
	# LMB is both `fire` and `primary_click`. Never staple-fire while placing
	# (ghost active) or on the place click flush (_suppress_primary_staple_click).
	if current_building_data != null:
		return false
	if ghost_building != null and is_instance_valid(ghost_building):
		return false
	if _suppress_primary_staple_click:
		return false
	if event.is_action_pressed("fire"):
		return true
	if event.is_action_pressed("primary_click"):
		return true
	return false

func _gui_blocks_world_fire() -> bool:
	if not is_inside_tree():
		return false
	var hovered: Control = get_viewport().gui_get_hovered_control()
	var n: Node = hovered
	while n:
		if n is BaseButton or n is LineEdit or n is TextEdit:
			return true
		n = n.get_parent()
	return false

func try_fire_staple_from_input() -> void:
	if not is_multiplayer_authority():
		return
	if is_combat_locked():
		return
	if _suppress_primary_staple_click:
		return
	# Queue until end of physics frame so same-frame melee (T006) can win.
	_queued_staple_fire = true

func _flush_queued_staple_fire() -> void:
	if _suppress_primary_staple_click:
		_suppress_primary_staple_click = false
		_queued_staple_fire = false
		return
	if not _queued_staple_fire:
		return
	_queued_staple_fire = false
	if not is_multiplayer_authority():
		return
	if is_combat_locked():
		return
	if _melee_swing_active:
		return
	if state_machine and state_machine.current_state and state_machine.current_state.name == "attack":
		return
	if Input.is_action_pressed("attack"):
		return
	var aim: Vector2 = cardinal_direction
	if is_inside_tree():
		var mouse_aim: Vector2 = get_global_mouse_position() - global_position
		if mouse_aim.length() >= 0.01:
			aim = mouse_aim
	if staple_count > 0:
		play_ranged_fire_animation()
	if multiplayer.is_server():
		request_fire_staple(aim)
	else:
		request_fire_staple.rpc_id(1, aim)

# Fire mapping: LMB is `fire` (and `primary_click` when not placing a building).
# Melee is `attack` (Space only). Building placement keeps primary_click.
# Owning client requests; host validates ammo, lockouts, and aim dir.
@rpc("any_peer", "reliable")
func request_fire_staple(aim: Vector2) -> void:
	if not multiplayer.is_server():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != get_multiplayer_authority():
		return
	_host_fire_staple(aim)

func _host_fire_staple(aim: Vector2) -> void:
	if is_combat_locked():
		return
	if _melee_swing_active:
		return
	if state_machine and state_machine.current_state and state_machine.current_state.name == "attack":
		return
	if staple_count <= 0:
		staple_count = 0
		_replicate_staple_count()
		# No jam/click SFX until audio exists. Empty fire fails silent.
		return
	var dir: Vector2 = aim
	if dir.length() < 0.01:
		dir = cardinal_direction
	else:
		dir = dir.normalized()
	staple_count -= 1
	if staple_count < 0:
		staple_count = 0
	_replicate_staple_count()
	var spawner: Node = _find_projectile_spawner()
	if spawner == null or not spawner.has_method("spawn_staple"):
		return
	var muzzle: Vector2 = global_position + dir * 18.0
	spawner.spawn_staple({
		"kind": "staple",
		"shooter_id": get_multiplayer_authority(),
		"position": muzzle,
		"direction": dir,
		"damage": staple_damage,
		"speed": staple_speed,
		"max_range": staple_max_range,
	})

func _find_projectile_spawner() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var nodes: Array = tree.get_nodes_in_group("projectile_spawner")
	if nodes.size() > 0:
		return nodes[0]
	return null

func _replicate_staple_count() -> void:
	_refresh_staple_hud()
	if not multiplayer.is_server():
		return
	var owner_id: int = get_multiplayer_authority()
	if owner_id <= 0 or owner_id == multiplayer.get_unique_id():
		return
	receive_staple_count.rpc_id(owner_id, staple_count)

@rpc("any_peer", "reliable")
func receive_staple_count(count: int) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != 1:
		return
	staple_count = maxi(0, count)
	_refresh_staple_hud()

func _refresh_staple_hud() -> void:
	staple_count_changed.emit(staple_count)
	if not is_multiplayer_authority():
		return
	if PlayerHud and PlayerHud.has_method("update_staple_magazine"):
		PlayerHud.update_staple_magazine(staple_count, staple_magazine_max)

func _input(event: InputEvent) -> void:
	# Live LMB cannot live only in _unhandled_input: HUD Controls consume the click.
	if not is_multiplayer_authority():
		return
	if not wants_fire_staple(event):
		return
	if _gui_blocks_world_fire():
		return
	try_fire_staple_from_input()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("primary_click"):
		if current_building_data and ghost_building:
			var place_id: String = current_building_data.resource_path
			var place_at: Vector2 = ghost_building.global_position
			if multiplayer.is_server():
				BuildingManager.request_placement(place_id, place_at, place_at)
			else:
				BuildingManager.request_placement.rpc_id(1, place_id, place_at, place_at)
			current_building_data = null
			_clear_ghost_building()
			# Same LMB must not also staple-fire after ghost clear.
			_suppress_primary_staple_click = true
			get_viewport().set_input_as_handled()

# =============================================================================
# DEATH SYSTEM INTEGRATION
# =============================================================================
func _on_player_respawn_completed(player_id: int, respawn_position: Vector2) -> void:
	"""Handle respawn completion - move to respawn position and reset state"""
	# Only handle for this player
	if player_id != get_multiplayer_authority():
		return
	
	print("Player ", player_id, " respawning at ", respawn_position)
	
	global_position = respawn_position
	enforce_map_interior()
	
	# Reset player state
	velocity = Vector2.ZERO
	hitpoints = max_hp
	invulnerable = false
	if multiplayer.is_server():
		sync_hitpoints.rpc(hitpoints)
	
	# The death state Exit() method will handle restoring visibility and collisions
	# This ensures consistency between all death/respawn pathways
	print("Player ", player_id, " respawn completed - death state will handle restoration")
	
	# Force to idle state if not already
	if TrailManager.shadow_mode_active:
		force_snake_state()
	else:
		force_idle_state()

func health_ratio() -> float:
	return float(hitpoints) / float(maxi(1, max_hp))

func take_damage(_hurt_box: Hurtbox) -> void:
	if not multiplayer.is_server():
		return
	if invulnerable:
		return
	cancel_fill()
	var dmg: int = 1
	if _hurt_box:
		dmg = maxi(1, _hurt_box.damage)
	hitpoints = hitpoints - dmg
	sync_hitpoints.rpc(hitpoints)
	if hitpoints <= 0:
		DeathSystem.request_player_death(int(name), position)

@rpc("any_peer", "call_local", "reliable")
func sync_hitpoints(hp: int) -> void:
	if not multiplayer.is_server():
		if multiplayer.get_remote_sender_id() != 1:
			return
	hitpoints = hp

func _spawn_health_bar() -> void:
	if HEALTH_BAR_SCENE == null:
		return
	if get_node_or_null("HealthBar") != null:
		_health_bar = get_node("HealthBar") as Node2D
		_refresh_health_bar()
		return
	_health_bar = HEALTH_BAR_SCENE.instantiate() as Node2D
	_health_bar.name = "HealthBar"
	_health_bar.position = Vector2(0.0, -86.0)
	add_child(_health_bar)
	_refresh_health_bar()

func _refresh_health_bar() -> void:
	if _health_bar == null or not is_instance_valid(_health_bar):
		_health_bar = get_node_or_null("HealthBar") as Node2D
	if _health_bar == null or not is_instance_valid(_health_bar):
		return
	_health_bar.visible = hitpoints > 0
	if _health_bar.has_method("set_health_ratio"):
		_health_bar.call("set_health_ratio", health_ratio())

func _configure_hp_replication() -> void:
	var sync := get_node_or_null("MultiplayerSynchronizer")
	if sync == null or sync.replication_config == null:
		return
	var config: SceneReplicationConfig = sync.replication_config
	var path := NodePath(".:hitpoints")
	if config.has_property(path):
		config.remove_property(path)


func _ensure_combat_visuals() -> void:
	if sprite:
		# Same 64 cell as N/S. Do not region-crop or scale E/W down.
		sprite.region_enabled = false
		sprite.hframes = 16
		sprite.vframes = 3
		sprite.texture = TEX_STAPLE_GUN
		sprite.scale = Vector2.ONE
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ensure_ink_slash()
	_rebuild_combat_animations()

func _ensure_ink_slash() -> void:
	var slash := get_node_or_null("MeleeInkSlash") as Sprite2D
	if slash == null:
		slash = Sprite2D.new()
		slash.name = "MeleeInkSlash"
		add_child(slash)
	slash.texture = TEX_INK_SLASH
	slash.hframes = 12
	slash.vframes = 1
	slash.visible = false
	slash.z_index = 2
	slash.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _rebuild_combat_animations() -> void:
	if animation_player == null:
		return
	var lib: AnimationLibrary = animation_player.get_animation_library("")
	if lib == null:
		lib = AnimationLibrary.new()
		animation_player.add_animation_library("", lib)
	var gun := {
		"down": {"idle": [0, 1], "walk": [2, 3, 4, 5], "fire": [6, 7]},
		"up": {"idle": [8, 9], "walk": [10, 11, 12, 13], "fire": [14, 15]},
		# cac03b2 dropped mini cells. E/W is the same 8-frame 64 grid as N/S.
		# Still no idle/breathe on sides (single plant frame). Scale stays 1,1.
		"right": {"idle": [16], "walk": [18, 19, 20, 21], "fire": [22, 23]},
		"left": {"idle": [24], "walk": [26, 27, 28, 29], "fire": [30, 31]},
	}
	# Packed DOWN/LEFT/RIGHT/UP, idle x2, walk x4, swing x3 (T005 / T008).
	var pencil := {
		"down": {"idle": [0, 1], "walk": [2, 3, 4, 5], "attack": [6, 7, 8]},
		"left": {"idle": [9, 10], "walk": [11, 12, 13, 14], "attack": [15, 16, 17]},
		"right": {"idle": [18, 19], "walk": [20, 21, 22, 23], "attack": [24, 25, 26]},
		"up": {"idle": [27, 28], "walk": [29, 30, 31, 32], "attack": [33, 34, 35]},
	}
	for d in ["down", "up", "left", "right"]:
		var side: bool = d == "left" or d == "right"
		_put_anim(lib, "idle_" + d, TEX_STAPLE_GUN, gun[d]["idle"], 0.1 if side else 0.4, not side, false, d)
		_put_anim(lib, "walk_" + d, TEX_STAPLE_GUN, gun[d]["walk"], 0.4, true, false, d)
		_put_anim(lib, "fire_" + d, TEX_STAPLE_GUN, gun[d]["fire"], 0.18, false, false, d)
		_put_anim(lib, "attack_" + d, TEX_PENCIL_MELEE, pencil[d]["attack"], 0.28, false, true, d)
	# Keep *_side as right-facing aliases for older play() calls.
	_put_anim(lib, "idle_side", TEX_STAPLE_GUN, gun["right"]["idle"], 0.1, false, false, "right")
	_put_anim(lib, "walk_side", TEX_STAPLE_GUN, gun["right"]["walk"], 0.4, true, false, "right")
	_put_anim(lib, "attack_side", TEX_PENCIL_MELEE, pencil["right"]["attack"], 0.28, false, true, "right")
	_put_anim(lib, "fire_side", TEX_STAPLE_GUN, gun["right"]["fire"], 0.18, false, false, "right")

func _put_anim(lib: AnimationLibrary, anim_name: String, tex: Texture2D, frames: Array, length: float, loop: bool, ink: bool, dir_name: String) -> void:
	var anim := Animation.new()
	anim.length = length
	anim.loop_mode = Animation.LOOP_PINGPONG if loop else Animation.LOOP_NONE
	var tex_i: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tex_i, NodePath("Sprite2D:texture"))
	anim.value_track_set_update_mode(tex_i, Animation.UPDATE_DISCRETE)
	anim.track_insert_key(tex_i, 0.0, tex)
	var fr_i: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(fr_i, NodePath("Sprite2D:frame"))
	anim.value_track_set_update_mode(fr_i, Animation.UPDATE_DISCRETE)
	var n: int = maxi(1, frames.size())
	for i in n:
		var t: float = 0.0 if n == 1 else length * float(i) / float(n)
		anim.track_insert_key(fr_i, t, int(frames[i]))
	var vis_i: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(vis_i, NodePath("MeleeInkSlash:visible"))
	anim.value_track_set_update_mode(vis_i, Animation.UPDATE_DISCRETE)
	anim.track_insert_key(vis_i, 0.0, ink)
	if ink:
		anim.track_insert_key(vis_i, maxf(0.0, length - 0.01), false)
		var ink_fr: int = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(ink_fr, NodePath("MeleeInkSlash:frame"))
		anim.value_track_set_update_mode(ink_fr, Animation.UPDATE_DISCRETE)
		for i in 12:
			anim.track_insert_key(ink_fr, length * float(i) / 12.0, i)
		var pos_i: int = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(pos_i, NodePath("MeleeInkSlash:position"))
		anim.value_track_set_update_mode(pos_i, Animation.UPDATE_DISCRETE)
		anim.track_insert_key(pos_i, 0.0, _ink_slash_position(dir_name))
		var rot_i: int = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(rot_i, NodePath("MeleeInkSlash:rotation"))
		anim.value_track_set_update_mode(rot_i, Animation.UPDATE_DISCRETE)
		anim.track_insert_key(rot_i, 0.0, _ink_slash_rotation(dir_name))
	if lib.has_animation(anim_name):
		lib.remove_animation(anim_name)
	lib.add_animation(anim_name, anim)

func _ink_slash_position(dir_name: String) -> Vector2:
	if dir_name == "down":
		return Vector2(0, 22)
	if dir_name == "up":
		return Vector2(0, -28)
	if dir_name == "left":
		return Vector2(-24, -8)
	return Vector2(24, -8)

func _ink_slash_rotation(dir_name: String) -> float:
	if dir_name == "down":
		return PI * 0.5
	if dir_name == "up":
		return -PI * 0.5
	if dir_name == "left":
		return PI
	return 0.0
