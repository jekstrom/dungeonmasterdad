class_name Gremlin extends Enemy
## US-013: dedicated gremlin actor (NOT goblin). Relocates world resources.
## Own sheet/VFX; carry-1 host-authoritative pickup/drop.

const GREMLIN_SHEET := "res://monsters/gremlin.png"
const GREMLIN_POOF := "res://monsters/gremlin_poof.png"

## Resource types gremlins may relocate (AC-1).
const RELOCATE_ITEMS: Array[String] = [
	"res://pickups/wood.tres",
	"res://pickups/metal.tres",
	"res://pickups/paper.tres",
	"res://pickups/blank_form.tres",
	"res://pickups/filled_form.tres",
	"res://pickups/tax_form.tres",
]

@export var move_speed: float = 70.0
@export var pickup_range_px: float = 22.0
@export var drop_delay_min_sec: float = 2.0
@export var drop_delay_max_sec: float = 6.0
@export var factory_prefer_radius_px: float = 220.0

enum RelocatePhase { SEEK, PICK, CARRY, WANDER }

var phase: RelocatePhase = RelocatePhase.SEEK
## Replicated carry payload (resource path). Empty = not carrying.
@export var carried_item_path: String = "":
	set(value):
		carried_item_path = value
		_refresh_carry_visual()

var _target_pickup: Node2D = null
var _drop_timer: float = 0.0
var _anim_t: float = 0.0
var _pick_t: float = 0.0
var _carry_visual: Sprite2D

func _ready() -> void:
	raids_buildings = false
	health_bar_title = "Gremlin"
	max_hp = 3
	hp = 3
	add_to_group("gremlins")
	add_to_group("monsters")
	super._ready()
	# Combat AI off — relocate only (FR-005).
	if enemy_state_machine:
		enemy_state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	var hitbox := get_node_or_null("Hitbox")
	if hitbox is Area2D:
		(hitbox as Area2D).set_deferred("monitoring", false)
		(hitbox as Area2D).set_deferred("monitorable", false)
	_ensure_sheet()
	_ensure_poof()
	_ensure_carry_visual()
	_configure_carry_replication()
	if multiplayer.is_server():
		phase = RelocatePhase.SEEK
		_retarget_pickup()


func _physics_process(delta: float) -> void:
	if _dying:
		velocity = Vector2.ZERO
		return
	if not multiplayer.is_server():
		_anim_t += delta
		_update_sprite_frame(velocity)
		return
	match phase:
		RelocatePhase.SEEK:
			_tick_seek(delta)
		RelocatePhase.PICK:
			_tick_pick(delta)
		RelocatePhase.CARRY:
			_tick_carry(delta)
		RelocatePhase.WANDER:
			_tick_wander(delta)
	move_and_slide()
	_enforce_map_interior()
	_anim_t += delta
	_update_sprite_frame(velocity)


func die() -> void:
	if multiplayer.is_server():
		_drop_carried_now()
	super.die()


func _take_damage(hurt_box: Hurtbox) -> void:
	# Optional: drop on damage — story allows delay OR damage policy; death always drops.
	super._take_damage(hurt_box)


# --- relocate AI (host) -----------------------------------------------------

func _tick_seek(delta: float) -> void:
	if carried_item_path != "":
		phase = RelocatePhase.CARRY
		_arm_drop_timer()
		return
	if _target_pickup == null or not is_instance_valid(_target_pickup) or not _is_claimable(_target_pickup):
		_retarget_pickup()
	if _target_pickup == null:
		_wander_step(delta)
		return
	var to: Vector2 = _target_pickup.global_position - global_position
	if to.length() <= pickup_range_px:
		velocity = Vector2.ZERO
		phase = RelocatePhase.PICK
		_pick_t = 0.25
		return
	SetDirection(to.normalized())
	velocity = to.normalized() * move_speed


func _tick_pick(delta: float) -> void:
	velocity = Vector2.ZERO
	_pick_t -= delta
	if _pick_t > 0.0:
		return
	if _target_pickup != null and is_instance_valid(_target_pickup) and _is_claimable(_target_pickup):
		var path := _claim_pickup(_target_pickup)
		if not path.is_empty():
			carried_item_path = path
			phase = RelocatePhase.CARRY
			_arm_drop_timer()
			_target_pickup = null
			return
	_target_pickup = null
	phase = RelocatePhase.SEEK


func _tick_carry(delta: float) -> void:
	_drop_timer -= delta
	# Walk away from claim spot so drop relocates the pile.
	if velocity.length() < 1.0:
		var dir := Vector2.RIGHT.rotated(randf() * TAU)
		SetDirection(dir)
		velocity = dir * move_speed
	if _drop_timer <= 0.0:
		_drop_carried_now()
		phase = RelocatePhase.SEEK
		_retarget_pickup()


func _tick_wander(delta: float) -> void:
	_wander_step(delta)
	phase = RelocatePhase.SEEK


func _wander_step(_delta: float) -> void:
	if velocity.length() < 1.0 or randf() < 0.02:
		var dir := Vector2.RIGHT.rotated(randf() * TAU)
		SetDirection(dir)
		velocity = dir * (move_speed * 0.55)


func _arm_drop_timer() -> void:
	_drop_timer = randf_range(drop_delay_min_sec, drop_delay_max_sec)


func _drop_carried_now() -> void:
	if carried_item_path.is_empty():
		return
	var path := carried_item_path
	carried_item_path = ""
	SignalBus.on_item_drop.emit({
		"item_type": path,
		"position": global_position,
		"velocity": Vector2.ZERO,
	})


func _claim_pickup(pickup: Node) -> String:
	if pickup == null or not multiplayer.is_server():
		return ""
	if pickup.has_method("claim_for_gremlin"):
		return str(pickup.call("claim_for_gremlin", self))
	return ""


func _is_claimable(pickup: Node) -> bool:
	if pickup == null or not is_instance_valid(pickup):
		return false
	if not pickup.visible:
		return false
	if pickup.get("can_be_picked_up") == false:
		return false
	var data = pickup.get("item_data")
	if data == null:
		return false
	var path := str(data.resource_path) if data.resource_path else ""
	return path in RELOCATE_ITEMS


func _retarget_pickup() -> void:
	_target_pickup = _choose_preferred_pickup()


func _choose_preferred_pickup() -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	var candidates: Array[Node2D] = []
	for node in tree.get_nodes_in_group("item_pickup"):
		if node is Node2D and _is_claimable(node):
			candidates.append(node as Node2D)
	# Fallback: scan ItemPickup class if group missing.
	if candidates.is_empty():
		var scene := tree.current_scene
		if scene:
			for node in scene.find_children("*", "ItemPickup", true, false):
				if node is Node2D and _is_claimable(node):
					candidates.append(node as Node2D)
	if candidates.is_empty():
		return null
	var anchors: Array[Vector2] = _factory_irs_anchors()
	var best: Node2D = null
	var best_score := INF
	for p in candidates:
		var dist := global_position.distance_to(p.global_position)
		var prefer := 0.0
		for a in anchors:
			var d_anchor := p.global_position.distance_to(a)
			if d_anchor <= factory_prefer_radius_px:
				prefer = maxf(prefer, (factory_prefer_radius_px - d_anchor) / factory_prefer_radius_px)
		# Lower score wins: distance with bonus for near-factory/IRS (FR-007).
		var score := dist * (1.0 - 0.55 * prefer)
		if score < best_score:
			best_score = score
			best = p
	return best


func _factory_irs_anchors() -> Array[Vector2]:
	var out: Array[Vector2] = []
	var tree := get_tree()
	if tree == null:
		return out
	for node in tree.get_nodes_in_group("factories"):
		if node is Node2D:
			out.append((node as Node2D).global_position)
	for node in tree.get_nodes_in_group("irs"):
		if node is Node2D:
			out.append((node as Node2D).global_position)
	# Name-based fallback.
	var scene := tree.current_scene
	if scene:
		for node in scene.find_children("*IRS*", "", true, false):
			if node is Node2D:
				out.append((node as Node2D).global_position)
		for node in scene.find_children("*Factory*", "", true, false):
			if node is Node2D:
				out.append((node as Node2D).global_position)
	return out


# --- visuals / sheet --------------------------------------------------------

func _ensure_sheet() -> void:
	if sprite == null:
		return
	var tex := load(GREMLIN_SHEET) as Texture2D
	if tex:
		sprite.texture = tex
	sprite.hframes = 8
	sprite.vframes = 3
	sprite.centered = true


func _ensure_poof() -> void:
	var effect := get_node_or_null("destroyEffectSprite") as Sprite2D
	if effect == null:
		return
	var tex := load(GREMLIN_POOF) as Texture2D
	if tex:
		effect.texture = tex
		effect.hframes = 4
		effect.vframes = 1


func _ensure_carry_visual() -> void:
	_carry_visual = get_node_or_null("CarryVisual") as Sprite2D
	if _carry_visual == null:
		_carry_visual = Sprite2D.new()
		_carry_visual.name = "CarryVisual"
		_carry_visual.position = Vector2(0, -10)
		_carry_visual.z_index = 1
		_carry_visual.visible = false
		# Generic brown block (sheet already has carry poses; this is extra cue).
		var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.45, 0.28, 0.12, 1))
		_carry_visual.texture = ImageTexture.create_from_image(img)
		add_child(_carry_visual)
	_refresh_carry_visual()


func _refresh_carry_visual() -> void:
	if _carry_visual:
		_carry_visual.visible = not carried_item_path.is_empty() and not _dying


func _configure_carry_replication() -> void:
	var sync := get_node_or_null("MultiplayerSynchronizer") as MultiplayerSynchronizer
	if sync == null:
		return
	var config := sync.replication_config
	if config == null:
		config = SceneReplicationConfig.new()
		sync.replication_config = config
	var path := NodePath(".:carried_item_path")
	if not config.has_property(path):
		config.add_property(path)
	config.property_set_spawn(path, true)
	config.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)


func _update_sprite_frame(vel: Vector2) -> void:
	if sprite == null or _dying:
		return
	var carrying := not carried_item_path.is_empty()
	var moving := vel.length() > 8.0
	var dir := cardinal_direction
	# West uses East frames flipped (GREMLIN_SHEET.md).
	var flip_w := dir == Vector2.LEFT
	sprite.flip_h = flip_w
	var col := 0
	var row := 0
	if phase == RelocatePhase.PICK and not carrying:
		row = 1 if dir == Vector2.DOWN else 2
		col = 7 if dir == Vector2.DOWN else (0 if dir == Vector2.UP else 1)
	elif carrying:
		row = 2
		if not moving:
			col = 2 if dir == Vector2.DOWN else (3 if dir == Vector2.UP else 4)
		else:
			col = 5 if dir == Vector2.DOWN else (7 if dir == Vector2.UP else 6)
	elif moving:
		var step := int(_anim_t * 8.0) % 4
		if dir == Vector2.DOWN:
			row = 0
			col = step
		elif dir == Vector2.UP:
			row = 0
			col = 4 + step
		else:
			row = 1
			col = step
	else:
		row = 1
		col = 4 if dir == Vector2.DOWN else (5 if dir == Vector2.UP else 6)
	sprite.frame = row * 8 + col


func UpdateAnimation(_state: String) -> void:
	# Sheet-driven; ignore goblin-style AnimationPlayer names.
	pass
