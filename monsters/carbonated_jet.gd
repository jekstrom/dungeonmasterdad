class_name CarbonatedJet extends Hurtbox

## US-027 T002/T003: piercing high-velocity neon Baja syrup stream.
## Visuals from sprites/baja_jet.png (512x128, 128x128 cells, hframes=4).
## NOT baja_boss_blast spit. NOT Freeze Wave. NOT fireball. NOT ColorRect syrup.
## Host resolves hits. Piercing: once per victim instance_id, then keep moving.
## user_stories/tasks/US-027/T002-piercing-stream.md
## user_stories/tasks/US-027/T003-replicate-jet.md

const JET_TEX := preload("res://sprites/baja_jet.png")
const WRAP_PX := 12.0
const BODY_CELL_X := 128.0
const CELL := 128.0
const IMPACT_SEC := 0.18

@export var speed: float = 900.0
@export var max_range: float = 768.0

var shooter_id: int = 0
var shooter: Node = null
var shooter_path: NodePath = NodePath()
var direction: Vector2 = Vector2.RIGHT
var _origin: Vector2 = Vector2.ZERO
var _consumed: bool = false
var _hit_ids: Dictionary = {}
var _wrap_px: float = 0.0
var _impact_world: Vector2 = Vector2.ZERO
var _impact_time: float = 0.0
var _fizz_t: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("carbonated_jets")
	collision_mask = collision_mask | 16
	monitoring = true
	monitorable = true
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	_origin = global_position
	if direction.length() < 0.001:
		direction = Vector2.RIGHT
	else:
		direction = direction.normalized()
	rotation = direction.angle()
	_ensure_sprites()
	if shooter == null and shooter_path != NodePath():
		var tree := get_tree()
		if tree:
			shooter = tree.root.get_node_or_null(shooter_path)


func _ensure_sprites() -> void:
	# Wire baja_jet.png cells. No ColorRect / Polygon2D syrup.
	var neon := get_node_or_null("Neon")
	if neon:
		neon.queue_free()
	_make_cell_sprite("Head", 0, Vector2.ZERO, false)
	_make_cell_sprite("Body", 1, Vector2(-CELL, 0.0), false)
	var fizz := _make_cell_sprite("Fizz", 2, Vector2(-CELL, 0.0), false)
	if fizz:
		fizz.modulate = Color(1, 1, 1, 0.55)
	var impact := _make_cell_sprite("Impact", 3, Vector2.ZERO, false)
	if impact:
		impact.visible = false
	# Body 12px wrap starts on first physics tick so spawn still shows frames 0/1.


func _make_cell_sprite(node_name: String, frame: int, pos: Vector2, region: bool) -> Sprite2D:
	var spr: Sprite2D = get_node_or_null(node_name) as Sprite2D
	if spr == null:
		spr = Sprite2D.new()
		spr.name = node_name
		add_child(spr)
	spr.texture = JET_TEX
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2.ONE
	spr.centered = true
	spr.position = pos
	spr.hframes = 4
	spr.vframes = 1
	spr.frame = frame
	spr.region_enabled = region
	return spr


func _apply_body_region(wrap: float) -> void:
	var body := get_node_or_null("Body") as Sprite2D
	if body == null:
		return
	# Body cell is index 1 at x=128. 12px wrap stays inside the cell (width 116).
	# hframes=1 while region_enabled so the 116px window is not subdivided.
	body.texture = JET_TEX
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.hframes = 1
	body.vframes = 1
	body.region_enabled = true
	body.region_rect = Rect2(BODY_CELL_X + wrap, 0.0, CELL - WRAP_PX, CELL)
	body.set_meta("jet_cell", 1)
	var fizz := get_node_or_null("Fizz") as Sprite2D
	if fizz:
		fizz.texture = JET_TEX
		fizz.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		fizz.hframes = 1
		fizz.vframes = 1
		fizz.position = body.position
		fizz.region_enabled = true
		fizz.region_rect = Rect2(CELL * 2.0 + wrap, 0.0, CELL - WRAP_PX, CELL)
		fizz.set_meta("jet_cell", 2)


func _physics_process(delta: float) -> void:
	if _consumed:
		return
	_wrap_px = fmod(_wrap_px + 120.0 * delta, WRAP_PX)
	_apply_body_region(_wrap_px)
	_fizz_t += delta
	var fizz := get_node_or_null("Fizz") as Sprite2D
	if fizz:
		# Alternate/overlay fizz on the body.
		fizz.modulate.a = 0.35 + 0.35 * absf(sin(_fizz_t * 12.0))
	if _impact_time > 0.0:
		_impact_time -= delta
		var impact := get_node_or_null("Impact") as Sprite2D
		if impact:
			impact.global_position = _impact_world
			if _impact_time <= 0.0:
				impact.visible = false
	if speed != 0.0:
		global_position += direction * speed * delta
	if global_position.distance_to(_origin) >= max_range:
		consume()
		return
	if _exited_map_interior():
		consume()
		return
	for area in get_overlapping_areas():
		_area_entered(area)
		if _consumed:
			return
	for body in get_overlapping_bodies():
		_on_body_entered(body)
		if _consumed:
			return


func _area_entered(area: Area2D) -> void:
	if _consumed:
		return
	if not (area is Hitbox):
		return
	var victim: Node = area.get_parent()
	if victim is BajaBoss:
		return
	if _is_shooter(victim) or _is_shooter(area):
		return
	var vid: int = victim.get_instance_id() if victim else area.get_instance_id()
	if _hit_ids.has(vid):
		return
	_hit_ids[vid] = true
	# Host-authored hits only. Client-only fake fire must not apply damage.
	# user_stories/tasks/US-027/T003-replicate-jet.md
	if multiplayer.is_server():
		area.take_damage(self)
	_show_impact(area.global_position)
	# PIERCING: do not consume() on first target. Stream keeps going.


func _show_impact(world_pos: Vector2) -> void:
	var impact := get_node_or_null("Impact") as Sprite2D
	if impact == null:
		return
	_impact_world = world_pos
	_impact_time = IMPACT_SEC
	impact.visible = true
	impact.frame = 3
	impact.global_position = world_pos


func _on_body_entered(body: Node) -> void:
	if _consumed:
		return
	if _is_shooter(body):
		return
	if body is BajaBoss:
		return
	# Do not wall or shove Paper Pushers (US-003 T011). Only walls/static stop us.
	if body is StaticBody2D:
		consume()
		return
	if body is CollisionObject2D and (body as CollisionObject2D).get_collision_layer_value(5):
		consume()


func _is_shooter(node: Node) -> bool:
	if node == null:
		return false
	var src: Node = shooter
	if src == null or not is_instance_valid(src):
		if shooter_path != NodePath():
			var tree := get_tree()
			if tree:
				src = tree.root.get_node_or_null(shooter_path)
				shooter = src
	if src != null and is_instance_valid(src):
		if node == src:
			return true
		if src.is_ancestor_of(node) or node.is_ancestor_of(src):
			return true
	if shooter_id != 0 and str(node.name) == str(shooter_id):
		return true
	return false


func _exited_map_interior() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	var level: Node = tree.get_first_node_in_group("level_manager")
	if level == null or not level.has_method("has_map_bounds") or not level.has_map_bounds():
		return false
	var bounds = level.get_map_bounds()
	if bounds.is_world_position_walkable(global_position):
		return false
	return true


func consume() -> void:
	if _consumed:
		return
	_consumed = true
	if area_entered.is_connected(_area_entered):
		area_entered.disconnect(_area_entered)
	if body_entered.is_connected(_on_body_entered):
		body_entered.disconnect(_on_body_entered)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	queue_free()
