class_name GoblinTrap extends Node2D

const STUN_SEC: float = 3.0
const TRIGGER_RADIUS: float = 56.0

@onready var sprite_2d_closed: Sprite2D = $Sprite2D_closed
@onready var sprite_2d_open: Sprite2D = $Sprite2D_open
@onready var area_2d: Area2D = $Area2D

@export var triggered: bool = false:
	set(value):
		triggered = value
		if is_node_ready():
			_apply_visual()

func _ready() -> void:
	add_to_group("goblin_traps")
	if area_2d:
		if not area_2d.body_entered.is_connected(_on_body_entered):
			area_2d.body_entered.connect(_on_body_entered)
		if not area_2d.area_entered.is_connected(_on_area_entered):
			area_2d.area_entered.connect(_on_area_entered)
		area_2d.collision_layer = 0
		area_2d.collision_mask = 3
		area_2d.monitoring = true
		area_2d.monitorable = false
	_apply_visual()

func _physics_process(_delta: float) -> void:
	if triggered:
		set_physics_process(false)
		return
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("players"):
		if node is Node2D and _is_near(node as Node2D):
			_spring_on(node)
			return

func _apply_visual() -> void:
	if sprite_2d_closed:
		sprite_2d_closed.visible = triggered
	if sprite_2d_open:
		sprite_2d_open.visible = not triggered

func _on_body_entered(body: Node2D) -> void:
	_try_trigger(body)

func _on_area_entered(area: Area2D) -> void:
	if area == null:
		return
	var host: Node = area.get_parent()
	if host == null:
		host = area
	_try_trigger(host)

func _try_trigger(node: Node) -> void:
	if triggered:
		return
	if not _is_paper_pusher(node):
		return
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		request_spring.rpc_id(1)
		return
	_spring_on(node)

@rpc("any_peer", "reliable")
func request_spring() -> void:
	if not multiplayer.is_server():
		return
	if triggered:
		return
	var victim: Node = _player_for_peer(multiplayer.get_remote_sender_id())
	if victim == null:
		return
	if victim is Node2D and not _is_near(victim as Node2D):
		return
	_spring_on(victim)

func _spring_on(victim: Node) -> void:
	if triggered:
		return
	triggered = true
	set_physics_process(false)
	if victim.has_method("take_damage"):
		victim.call("take_damage", null)
	var peer_id: int = victim.get_multiplayer_authority()
	broadcast_stun.rpc(peer_id, STUN_SEC)

@rpc("authority", "call_local", "reliable")
func broadcast_stun(peer_id: int, duration: float) -> void:
	var victim: Node = _player_for_peer(peer_id)
	if victim == null:
		return
	if victim.has_method("begin_trap_stun"):
		victim.call("begin_trap_stun", duration)
	elif victim.has_method("apply_trap_stun"):
		victim.call("apply_trap_stun", duration)

func _player_for_peer(peer_id: int) -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("players"):
		if node.get_multiplayer_authority() == peer_id:
			return node
	return null

func _is_near(body: Node2D) -> bool:
	return global_position.distance_to(body.global_position) <= TRIGGER_RADIUS

func _is_paper_pusher(body: Node) -> bool:
	if body == null or not is_instance_valid(body):
		return false
	if body is Player:
		return true
	return body.is_in_group("players")
