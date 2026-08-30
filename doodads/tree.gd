@tool
class_name TreeDoodad extends Node2D

const WOOD_ITEM := "res://pickups/wood.tres"
const STUMP_TEXTURE: Texture2D = preload("res://sprites/tree_stump.png")
const LIVING_SPRITE_SCALE := Vector2(5, 5)
const LIVING_SPRITE_POS := Vector2(0, -80)
const STUMP_SPRITE_SCALE := Vector2(1.6, 1.6)
const STUMP_SPRITE_POS := Vector2(0, -26)
const HARVEST_HINT_RANGE := 64.0

@export var tree_type: int = -1: set = _set_tree_type
@export var hits_required: int = 3
@export var wood_yield_min: int = 3
@export var wood_yield_max: int = 6
@export var hits_taken: int = 0
@export var is_stump: bool = false
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var harvest_hitbox: Hitbox = $Hitbox

var _hit_hurtboxes: Dictionary = {}

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		_ensure_unique_texture()

func _ready() -> void:
	_ensure_unique_texture()
	if is_stump:
		_apply_stump_visual()
	else:
		_update_texture()
	if Engine.is_editor_hint():
		return
	add_to_group("harvest_trees")
	if harvest_hitbox and not harvest_hitbox.Damaged.is_connected(_on_harvest_damaged):
		harvest_hitbox.Damaged.connect(_on_harvest_damaged)

func _update_texture() -> void:
	if is_stump:
		_apply_stump_visual()
		return
	if not _resolve_sprite():
		return
	if not sprite_2d.texture is AtlasTexture:
		return
	if tree_type < 0:
		tree_type = randi_range(0, 9)
	(sprite_2d.texture as AtlasTexture).region = Rect2(tree_type * 32, 0, 32, 32)

func _set_tree_type(_value: int) -> void:
	tree_type = _value
	if not is_inside_tree() or not _resolve_sprite():
		if Engine.is_editor_hint():
			call_deferred("_apply_tree_type")
		return
	_apply_tree_type()

func _apply_tree_type() -> void:
	_ensure_unique_texture()
	_update_texture()

func _ensure_unique_texture() -> void:
	if is_stump:
		return
	if not _resolve_sprite():
		return
	if not sprite_2d.texture:
		return
	if sprite_2d.texture is AtlasTexture:
		var owner_id := get_instance_id()
		var texture_owner_id = sprite_2d.texture.get_meta("tree_owner_id", -1)
		if texture_owner_id != owner_id:
			var unique_texture = sprite_2d.texture.duplicate(true) as AtlasTexture
			unique_texture.resource_local_to_scene = true
			unique_texture.set_meta("tree_owner_id", owner_id)
			sprite_2d.texture = unique_texture

func _resolve_sprite() -> bool:
	if sprite_2d:
		return true
	sprite_2d = get_node_or_null("Sprite2D")
	return sprite_2d != null

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
	if is_stump:
		return false
	if hits_taken >= hits_required:
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

func apply_harvest_hit(striker: Node) -> bool:
	if Engine.is_editor_hint():
		return false
	if not multiplayer.is_server():
		return false
	if not can_harvest_from(striker):
		return false
	hits_taken += 1
	if hits_taken < hits_required:
		_replicate_harvest_state()
		return true
	hits_taken = hits_required
	_become_stump()
	_grant_wood(striker)
	_replicate_harvest_state()
	return true

func apply_replicated_harvest_state(hits: int, stump: bool) -> void:
	hits_taken = hits
	is_stump = stump
	if stump:
		_apply_stump_visual()

func _become_stump() -> void:
	if is_stump:
		return
	is_stump = true
	_apply_stump_visual()

func _apply_stump_visual() -> void:
	is_stump = true
	if harvest_hitbox == null:
		harvest_hitbox = get_node_or_null("Hitbox") as Hitbox
	if harvest_hitbox:
		harvest_hitbox.set_deferred("monitorable", false)
		harvest_hitbox.set_deferred("collision_layer", 0)
	if not _resolve_sprite():
		return
	sprite_2d.texture = STUMP_TEXTURE
	sprite_2d.scale = STUMP_SPRITE_SCALE
	sprite_2d.position = STUMP_SPRITE_POS

func _grant_wood(striker: Node) -> void:
	var lo: int = mini(wood_yield_min, wood_yield_max)
	var hi: int = maxi(wood_yield_min, wood_yield_max)
	var amount: int = randi_range(lo, hi)
	var player_id: int = _player_id_of(striker)
	var wood: ItemData = ItemDatabase.get_item(WOOD_ITEM)
	if wood == null:
		wood = load(WOOD_ITEM) as ItemData
	if wood == null:
		return
	PlayerManager.grant_item_or_drop(player_id, wood, amount, global_position)

func _replicate_harvest_state() -> void:
	if not multiplayer.is_server():
		return
	sync_harvest_state.rpc(hits_taken, is_stump)

@rpc("authority", "call_remote", "reliable")
func sync_harvest_state(hits: int, stump: bool) -> void:
	apply_replicated_harvest_state(hits, stump)

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
	var tree_cell: Vector2i = DungeonGrid.from_world(global_position)
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
			if DungeonGrid.from_world(body.global_position) == tree_cell:
				return true
			var shape: CollisionShape2D = child.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if shape and shape.shape is RectangleShape2D:
				var rect_size: Vector2 = (shape.shape as RectangleShape2D).size
				var center: Vector2 = body.global_position + shape.position
				var footprint := Rect2(center - rect_size * 0.5, rect_size)
				if footprint.has_point(global_position):
					return true
	return false
