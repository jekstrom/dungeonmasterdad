@tool
class_name WallDoodad extends Node2D

const WALL_Z_INDEX := 0

# wall_type is the collider: 1 = horizontal, 2 = vertical (generator contract).
# wall_frame is the atlas index from cubicle_stone_wall.png. 4 is shadow-only.
# Frames 0-16 keep the old cubicle indices; 17-20 are T-junctions, 21 is +.
@export var wall_type: int = -1: set = _set_wall_type
@export var wall_frame: int = -1: set = _set_wall_frame
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $StaticBody/CollisionShape2D
@onready var collision_shape_v: CollisionShape2D = $StaticBody/CollisionShapeVertical
@onready var shadow: Sprite2D = $StaticBody/Shadow
@onready var floor_underlay: Sprite2D = $FloorUnderlay

# N=1 E=2 S=4 W=8. Matches cubicle_stone_wall.png frames.
const FRAME_DIRS: Array[int] = [
	10, 5, 12, 9, 0, 3, 6, 2, 8, 4, 1, 10, 5, 4, 1, 12, 9, 11, 7, 14, 13, 15, 2, 8,
	6, 12, 3, 9,
]
# All pieces share the centered 40px grid so H/V/T/corners meet.
const FRAME_HUG: Array[int] = [
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0,
]
const WALL_THICK := 40.0
const WALL_FACE := 44.0
# Sprite is a direct y-sorted child. Position is the sort key (south edge of
# the tile / foot of the 3/4 face). Offset keeps pixels on the 128 grid.
# Player south of that line draws in front; player north draws behind.
const SPRITE_GRID_Y := -63.0

func _enter_tree() -> void:
	z_index = WALL_Z_INDEX
	y_sort_enabled = true
	if Engine.is_editor_hint():
		_ensure_unique_texture()

func _ready() -> void:
	z_index = WALL_Z_INDEX
	y_sort_enabled = true
	_ensure_unique_texture()
	_update_texture()
	if Engine.is_editor_hint():
		return
	_smoke_generated_tile()

func _update_texture() -> void:
	if not _resolve_sprite():
		return
	if not sprite_2d.texture is AtlasTexture:
		return
	if wall_type < 0:
		wall_type = 1
	var frame: int = _resolved_frame()
	(sprite_2d.texture as AtlasTexture).region = Rect2(frame * 128, 0, 128, 128)
	# Sort at the wall node (south foot). Offset restores the grid-aligned art.
	sprite_2d.position = Vector2.ZERO
	sprite_2d.offset = Vector2(0, SPRITE_GRID_Y)
	_update_collision(frame)
	_update_floor_underlay()
	if shadow:
		shadow.visible = wall_type != 2
		shadow.position = Vector2(0, -80)


func _update_collision(frame: int) -> void:
	if not collision_shape_2d:
		return
	var idx: int = clampi(frame, 0, FRAME_DIRS.size() - 1)
	var dirs: int = FRAME_DIRS[idx]
	var hug: int = FRAME_HUG[idx]
	var n: bool = bool(dirs & 1)
	var e: bool = bool(dirs & 2)
	var s: bool = bool(dirs & 4)
	var w: bool = bool(dirs & 8)
	var hug_n: bool = bool(hug & 1)
	var hug_s: bool = bool(hug & 2)
	var hug_e: bool = bool(hug & 4)
	var hug_w: bool = bool(hug & 8)
	var ox: float = 0.0 if hug_w else (128.0 - WALL_THICK if hug_e else 44.0)
	var oy: float = 0.0 if hug_n else (128.0 - WALL_FACE - WALL_THICK if hug_s else 44.0)
	var has_h: bool = e or w
	var has_v: bool = n or s
	# Cap is visual height, not a floor blocker. Collide with the south face
	# so the player can walk behind the wall from the north, then stop at the
	# foot. Texture (tx,ty) -> (tx-64, ty-127) with sprite offset (0,-63).
	var foot_y0: float = oy + WALL_THICK
	var foot_y1: float = 128.0
	if has_h:
		var hx0: float = 0.0 if w else ox
		var hx1: float = 128.0 if e else ox + WALL_THICK
		_set_rect(collision_shape_2d, hx0, foot_y0, hx1, foot_y1)
		collision_shape_2d.disabled = false
	else:
		collision_shape_2d.disabled = true
	if collision_shape_v:
		if has_v:
			# Keep a full-height column when this tile connects north so stacked
			# V pieces do not leave a gap. North end-caps open the cap.
			var vy0: float = 0.0 if n else foot_y0
			_set_rect(collision_shape_v, ox, vy0, ox + WALL_THICK, foot_y1)
			collision_shape_v.disabled = false
		else:
			collision_shape_v.disabled = true
	if not has_h and not has_v:
		if wall_type == 2:
			if collision_shape_v:
				_set_rect(collision_shape_v, ox, 0.0, ox + WALL_THICK, 128.0)
				collision_shape_v.disabled = false
		else:
			_set_rect(collision_shape_2d, 0.0, foot_y0, 128.0, foot_y1)
			collision_shape_2d.disabled = false


func _set_rect(node: CollisionShape2D, tx0: float, ty0: float, tx1: float, ty1: float) -> void:
	node.rotation_degrees = 0.0
	node.position = Vector2((tx0 + tx1) * 0.5 - 64.0, (ty0 + ty1) * 0.5 - 127.0)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(tx1 - tx0, ty1 - ty0)
	node.shape = shape


func _update_floor_underlay() -> void:
	if not floor_underlay:
		floor_underlay = get_node_or_null("FloorUnderlay")
	if not floor_underlay or not floor_underlay.texture is AtlasTexture:
		return
	var gx := int(round(position.x / 128.0))
	var gy := int(round(position.y / 128.0))
	var visual: int = posmod(gx, 4) + posmod(gy, 4) * 4
	var tex := floor_underlay.texture as AtlasTexture
	if tex.get_meta("wall_owner_id", -1) != get_instance_id():
		tex = tex.duplicate(true) as AtlasTexture
		tex.resource_local_to_scene = true
		tex.set_meta("wall_owner_id", get_instance_id())
		floor_underlay.texture = tex
	tex.region = Rect2(visual * 128, 0, 128, 128)


func _resolved_frame() -> int:
	var frame: int = wall_frame
	if frame == 4:
		frame = 0
	if frame < 0:
		# Playground instances: type 2 is the vertical collider. Frame 1 is
		# V middle. Generated walls always set wall_frame.
		if wall_type == 2:
			frame = 1
		else:
			frame = 0
	return clampi(frame, 0, 27)

func _set_wall_type(_value: int) -> void:
	wall_type = _value
	if not is_inside_tree() or not _resolve_sprite():
		if Engine.is_editor_hint():
			call_deferred("_apply_wall_type")
		return
	_apply_wall_type()

func _set_wall_frame(_value: int) -> void:
	wall_frame = _value
	if not is_inside_tree() or not _resolve_sprite():
		if Engine.is_editor_hint():
			call_deferred("_apply_wall_type")
		return
	_apply_wall_type()

func _apply_wall_type() -> void:
	_ensure_unique_texture()
	_update_texture()

func _ensure_unique_texture() -> void:
	if not _resolve_sprite():
		return
	if not sprite_2d.texture:
		return
	if sprite_2d.texture is AtlasTexture:
		var owner_id := get_instance_id()
		var texture_owner_id = sprite_2d.texture.get_meta("wall_owner_id", -1)
		if texture_owner_id != owner_id:
			var unique_texture = sprite_2d.texture.duplicate(true) as AtlasTexture
			unique_texture.resource_local_to_scene = true
			unique_texture.set_meta("wall_owner_id", owner_id)
			sprite_2d.texture = unique_texture

func _resolve_sprite() -> bool:
	if not sprite_2d:
		sprite_2d = get_node_or_null("Sprite2D")
	if not sprite_2d:
		sprite_2d = get_node_or_null("StaticBody/Sprite2D")
	if not collision_shape_2d:
		collision_shape_2d = get_node_or_null("StaticBody/CollisionShape2D")
	if not collision_shape_v:
		collision_shape_v = get_node_or_null("StaticBody/CollisionShapeVertical")
	if not shadow:
		shadow = get_node_or_null("StaticBody/Shadow")
	return sprite_2d != null

func _smoke_generated_tile() -> void:
	if not is_in_group("generated_dungeon_tiles"):
		return
	var px := int(round(position.x))
	var py := int(round(position.y))
	if px % 128 != 0 or py % 128 != 0:
		push_warning("WallDoodad: generated tile off-grid at %s wall_type=%d wall_frame=%d (peer=%d)" % [position, wall_type, wall_frame, multiplayer.get_unique_id()])
