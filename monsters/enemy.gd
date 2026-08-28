class_name Enemy extends CharacterBody2D

const DungeonGridScript = preload("res://scripts/procedural_dungeon/dungeon_grid.gd")

signal direction_changed(new_direction: Vector2)
#signal enemy_damaged(hurt_box: Hurtbox)
#signal enemy_destroyed(hurt_box: Hurtbox)
const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

enum AggroFaction { DM, PLAYERS, BOTH }

var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO
var player: Player
var invulnerable: bool = false
var aggro_target: Node2D = null

@export var max_hp: int = 4
@export var hp: int = 4:
	set(value):
		hp = clampi(value, 0, maxi(1, max_hp) if max_hp > 0 else maxi(0, value))
		_refresh_health_bar()
@export var aggro_faction: AggroFaction = AggroFaction.DM
@export var melee_range_px: float = 128.0
var _dying: bool = false
var _health_bar: Node2D

const HEALTH_BAR_SCENE: PackedScene = preload("res://monsters/enemy_health_bar.tscn")

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var enemy_state_machine: EnemyStateMachine = $EnemyStateMachine
#@onready var hurtbox: Hurtbox = $Hurtbox
#@onready var hitbox: Hitbox = $Hitbox

func _ready() -> void:
	if max_hp < hp:
		max_hp = hp
	if max_hp <= 0:
		max_hp = 1
	hp = mini(hp, max_hp)
	enemy_state_machine.initialize(self)
	player = PlayerManager.player
	_spawn_health_bar()
	_configure_hp_replication()
	var hitbox := get_node_or_null("Hitbox")
	if hitbox and hitbox.has_signal("Damaged"):
		hitbox.Damaged.connect(_take_damage)

func _process(_delta: float) -> void:
	pass

func SetDirection(_new_direction: Vector2) -> bool:
	if _new_direction == Vector2.ZERO:
		return false
		
	direction = _new_direction
	
	var direction_id: int = int(round((direction + cardinal_direction * 0.1).angle() / TAU * DIR_4.size()))
	var new_dir = DIR_4[direction_id]
		
	if new_dir == cardinal_direction:
		return false
	
	cardinal_direction = new_dir
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	
	direction_changed.emit(new_dir)
	
	return true
	
func dm_distance() -> float:
	if DmManager.dm == null or not is_instance_valid(DmManager.dm):
		return INF
	return global_position.distance_to(DmManager.dm.global_position)


func screen_spot_range() -> float:
	var viewport := get_viewport()
	if viewport == null:
		return 160.0
	var size: Vector2 = viewport.get_visible_rect().size
	var zoom: float = 1.0
	var camera := viewport.get_camera_2d()
	if camera:
		zoom = minf(camera.zoom.x, camera.zoom.y)
		if zoom <= 0.0:
			zoom = 1.0
	return 0.25 * maxf(size.x, size.y) / zoom


func can_see_dm() -> bool:
	return has_aggro_target() and aggro_target is DM


func acquire_aggro_target() -> Node2D:
	aggro_target = _closest_aggro_candidate()
	return aggro_target


func has_aggro_target() -> bool:
	return acquire_aggro_target() != null


func aggros_on_dm() -> bool:
	return aggro_faction != AggroFaction.PLAYERS


func can_melee_current_target() -> bool:
	return is_melee_close_to(aggro_target)


func can_damage_dm() -> bool:
	return aggros_on_dm() and is_melee_close_to(DmManager.dm)


func is_melee_close_to(node: Node2D) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if global_position.distance_to(node.global_position) > melee_range_px:
		return false
	var self_cell: Vector2i = DungeonGridScript.from_world(global_position)
	var other_cell: Vector2i = DungeonGridScript.from_world(node.global_position)
	return DungeonGridScript.chebyshev(self_cell, other_cell) <= 1


func _closest_aggro_candidate() -> Node2D:
	var best: Node2D = null
	var best_dist: float = screen_spot_range()
	for candidate in _aggro_candidates():
		var dist: float = global_position.distance_to(candidate.global_position)
		if dist <= best_dist:
			best_dist = dist
			best = candidate
	return best


func _aggro_candidates() -> Array[Node2D]:
	var candidates: Array[Node2D] = []
	if aggro_faction != AggroFaction.PLAYERS:
		if DmManager.dm != null and is_instance_valid(DmManager.dm) and DmManager.dm.is_inside_tree():
			candidates.append(DmManager.dm)
	if aggro_faction != AggroFaction.DM:
		var tree := get_tree()
		if tree:
			for node in tree.get_nodes_in_group("players"):
				if node is Node2D and is_instance_valid(node) and node.is_inside_tree():
					candidates.append(node)
	return candidates


@warning_ignore("unused_parameter")
func _physics_process(_delta: float) -> void:
	if _dying:
		velocity = Vector2.ZERO
		return
	move_and_slide()


func health_ratio() -> float:
	return float(hp) / float(maxi(1, max_hp))


func _spawn_health_bar() -> void:
	if HEALTH_BAR_SCENE == null:
		return
	_health_bar = HEALTH_BAR_SCENE.instantiate() as Node2D
	_health_bar.name = "HealthBar"
	var bar_y: float = -32.0
	if sprite:
		bar_y = sprite.position.y - 32.0
	_health_bar.position = Vector2(0.0, bar_y)
	add_child(_health_bar)
	_refresh_health_bar()


func _refresh_health_bar() -> void:
	if _health_bar and is_instance_valid(_health_bar) and _health_bar.has_method("set_health_ratio"):
		_health_bar.call("set_health_ratio", health_ratio())


func _configure_hp_replication() -> void:
	var sync := get_node_or_null("MultiplayerSynchronizer")
	if sync == null or sync.replication_config == null:
		return
	var path := NodePath(".:hp")
	var config: SceneReplicationConfig = sync.replication_config
	if not config.has_property(path):
		config.add_property(path)
	config.property_set_spawn(path, true)
	config.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)


func _take_damage(hurt_box: Hurtbox) -> void:
	if not multiplayer.is_server():
		return
	if _dying or invulnerable:
		return
	hp -= hurt_box.damage
	if hp <= 0:
		die()


func die() -> void:
	if _dying:
		return
	if not multiplayer.is_server():
		return
	play_death.rpc()
	var tree := get_tree()
	if tree:
		tree.create_timer(0.65).timeout.connect(queue_free)
	else:
		queue_free()


@rpc("authority", "call_local", "reliable")
func play_death() -> void:
	if _dying:
		return
	_dying = true
	velocity = Vector2.ZERO
	if enemy_state_machine:
		enemy_state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	if _health_bar and is_instance_valid(_health_bar):
		_health_bar.visible = false
	if sprite:
		sprite.visible = false
	var shadow := get_node_or_null("shadow")
	if shadow is CanvasItem:
		(shadow as CanvasItem).visible = false
	var collision := get_node_or_null("CollisionShape2D")
	if collision is CollisionShape2D:
		(collision as CollisionShape2D).set_deferred("disabled", true)
	var hurtbox := get_node_or_null("Hurtbox")
	if hurtbox is Area2D:
		(hurtbox as Area2D).monitoring = false
		(hurtbox as Area2D).monitorable = false
	var effect := get_node_or_null("destroyEffectSprite")
	if effect is CanvasItem:
		(effect as CanvasItem).visible = true
		var effect_player := effect.get_node_or_null("AnimationPlayer")
		if effect_player is AnimationPlayer:
			(effect_player as AnimationPlayer).play("destroy")
	
func UpdateAnimation(state: String) -> void:
	animation_player.play(state + "_" + AnimDirection())

func AnimDirection() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	return "side"

#func _take_damage(hurt_box: Hurtbox) -> void:
	#pass
	#if invulnerable:
		#return
	#hp -= hurt_box.damage
	#if hp > 0:
		#enemy_damaged.emit(hurt_box)
	#else:
		#enemy_destroyed.emit(hurt_box)
