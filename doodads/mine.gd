class_name MineDoodad extends Node2D

const IRON_ITEM := "res://pickups/metal.tres"
const ACTIVE_TEXTURE: Texture2D = preload("res://sprites/mine_active.png")
const DEPLETED_TEXTURE: Texture2D = preload("res://sprites/mine_depleted.png")
const HARVEST_HINT_RANGE := 64.0

@export var hits_required: int = 4
@export var iron_per_yield: int = 1
@export var yields_before_deplete: int = 5
@export var regen_cooldown: float = 30.0
@export var hits_taken: int = 0
@export var yields_taken: int = 0
@export var is_depleted: bool = false

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var harvest_hitbox: Hitbox = $Hitbox

var _hit_hurtboxes: Dictionary = {}
var _regen_timer: float = 0.0

func _enter_tree() -> void:
	y_sort_enabled = true
	z_index = 0

func _ready() -> void:
	add_to_group("mines")
	add_to_group("harvest_nodes")
	_apply_visual()
	if harvest_hitbox and not harvest_hitbox.Damaged.is_connected(_on_harvest_damaged):
		harvest_hitbox.Damaged.connect(_on_harvest_damaged)

func _process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if not is_depleted:
		return
	if regen_cooldown <= 0.0:
		return
	_regen_timer += delta
	if _regen_timer >= regen_cooldown:
		_regenerate()

func _on_harvest_damaged(hurt_box: Hurtbox) -> void:
	if hurt_box == null:
		return
	var token: int = hurt_box.get_instance_id()
	if _hit_hurtboxes.has(token):
		return
	_hit_hurtboxes[token] = true
	apply_harvest_hit(hurt_box.get_parent())
	var scene_tree := get_tree()
	if scene_tree:
		scene_tree.create_timer(0.2).timeout.connect(func() -> void:
			_hit_hurtboxes.erase(token)
		)

func can_harvest_from(striker: Node) -> bool:
	if is_depleted:
		return false
	if striker == null or not is_instance_valid(striker):
		return false
	if striker is DM:
		return false
	if not (striker is Player):
		return false
	if _is_fantasy_claimed(_world_of(striker)):
		return false
	if _is_fantasy_claimed(global_position):
		return false
	if _is_under_building():
		return false
	return true

func is_harvest_prompt_target(striker: Node) -> bool:
	if not can_harvest_from(striker):
		return false
	if not (striker is Node2D):
		return false
	return (striker as Node2D).global_position.distance_to(global_position) <= HARVEST_HINT_RANGE

func shows_harvest_progress() -> bool:
	if is_depleted:
		return false
	return hits_taken > 0 and hits_required > 0

func harvest_progress() -> float:
	if hits_required <= 0:
		return 0.0
	return clampf(float(hits_taken) / float(hits_required), 0.0, 1.0)

func apply_harvest_hit(striker: Node) -> bool:
	if not multiplayer.is_server():
		return false
	if not can_harvest_from(striker):
		return false
	hits_taken += 1
	if hits_taken < hits_required:
		_replicate_mine_state()
		return true
	hits_taken = 0
	_grant_iron(striker)
	yields_taken += 1
	if yields_taken >= yields_before_deplete:
		_deplete()
	_replicate_mine_state()
	return true

func apply_replicated_mine_state(hits: int, yields: int, depleted: bool) -> void:
	hits_taken = hits
	yields_taken = yields
	is_depleted = depleted
	if depleted:
		_regen_timer = 0.0
	_apply_visual()

func _deplete() -> void:
	is_depleted = true
	_regen_timer = 0.0
	hits_taken = 0
	_apply_visual()

func _regenerate() -> void:
	is_depleted = false
	yields_taken = 0
	hits_taken = 0
	_regen_timer = 0.0
	_apply_visual()
	_replicate_mine_state()

func _apply_visual() -> void:
	if sprite_2d == null:
		sprite_2d = get_node_or_null("Sprite2D") as Sprite2D
	if harvest_hitbox == null:
		harvest_hitbox = get_node_or_null("Hitbox") as Hitbox
	if sprite_2d:
		sprite_2d.y_sort_enabled = false
		sprite_2d.position = Vector2.ZERO
		sprite_2d.scale = Vector2(2.5, 2.5)
		sprite_2d.offset = Vector2.ZERO
		sprite_2d.texture = DEPLETED_TEXTURE if is_depleted else ACTIVE_TEXTURE
	if harvest_hitbox:
		harvest_hitbox.set_deferred("monitorable", not is_depleted)
		harvest_hitbox.set_deferred("collision_layer", 0 if is_depleted else 8)

func _grant_iron(striker: Node) -> void:
	var amount: int = maxi(1, iron_per_yield)
	var player_id: int = _player_id_of(striker)
	var iron: ItemData = ItemDatabase.get_item(IRON_ITEM)
	if iron == null:
		iron = load(IRON_ITEM) as ItemData
	if iron == null:
		return
	PlayerManager.grant_item_or_drop(player_id, iron, amount, global_position)

func _replicate_mine_state() -> void:
	if not multiplayer.is_server():
		return
	sync_mine_state.rpc(hits_taken, yields_taken, is_depleted)

@rpc("authority", "call_remote", "reliable")
func sync_mine_state(hits: int, yields: int, depleted: bool) -> void:
	apply_replicated_mine_state(hits, yields, depleted)

func _player_id_of(striker: Node) -> int:
	if striker == null:
		return 0
	if striker is Player:
		var auth: int = striker.get_multiplayer_authority()
		if auth > 0:
			return auth
		if striker.name.is_valid_int():
			return int(striker.name)
	return 0

func _world_of(node: Node) -> Vector2:
	if node is Node2D:
		return (node as Node2D).global_position
	return global_position

func _is_fantasy_claimed(world: Vector2) -> bool:
	var scene_tree := get_tree()
	if scene_tree == null:
		return false
	var zone: Node = scene_tree.get_first_node_in_group("FantasyZone")
	if zone == null or not zone.has_method("is_claimed_world"):
		return false
	return bool(zone.is_claimed_world(world))

func _is_under_building() -> bool:
	var scene_tree := get_tree()
	if scene_tree == null:
		return false
	var mine_cell: Vector2i = DungeonGrid.from_world(global_position)
	for root in scene_tree.get_nodes_in_group("building_root"):
		if root == null:
			continue
		for child in root.get_children():
			if not is_instance_valid(child):
				continue
			if child is Building and child.is_ghost:
				continue
			if not (child is Node2D):
				continue
			var body: Node2D = child as Node2D
			if DungeonGrid.from_world(body.global_position) == mine_cell:
				return true
			var shape: CollisionShape2D = child.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if shape and shape.shape is RectangleShape2D:
				var rect_size: Vector2 = (shape.shape as RectangleShape2D).size
				var center: Vector2 = body.global_position + shape.position
				var footprint := Rect2(center - rect_size * 0.5, rect_size)
				if footprint.has_point(global_position):
					return true
	return false
