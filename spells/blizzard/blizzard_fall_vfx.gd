class_name BlizzardFallVfx extends Node2D

const SNOWFLAKE_PATH := "res://spells/blizzard/snowflake.png"
const ICICLE_PATH := "res://spells/blizzard/icicle.png"
const SPARKLE_PATH := "res://sprites/fantasy_sparkle.png"
const PUFF_PATH := "res://sprites/fantasy_drift_puff.png"
const SPARKS_PATH := "res://sprites/sparks.png"
const FRAME_PX := 32
const EMIT_TOP_PX := 64.0
const EDGE_INSET_PX := 18.0

var _world_rect: Rect2 = Rect2()
var _snow: CPUParticles2D
var _icicles: CPUParticles2D


func _ready() -> void:
	add_to_group("blizzard_fall_vfx")
	y_sort_enabled = false
	z_as_relative = false
	z_index = 16
	top_level = true
	_snow = _make_emitter(SNOWFLAKE_PATH, 34, 2.0, 90.0, 140.0, Vector2(0.0, 40.0), 0.55, 0.85)
	_snow.name = "Snow"
	_icicles = _make_emitter(ICICLE_PATH, 11, 1.5, 130.0, 190.0, Vector2(0.0, 70.0), 0.65, 1.0)
	_icicles.name = "Icicles"
	if not _world_rect.has_area():
		return
	_apply_rect(_world_rect)


func configure(world_rect: Rect2) -> void:
	_world_rect = world_rect
	if not is_inside_tree():
		return
	_apply_rect(world_rect)


func world_rect() -> Rect2:
	return _world_rect


func snowflake_path() -> String:
	return SNOWFLAKE_PATH


func icicle_path() -> String:
	return ICICLE_PATH


func _apply_rect(world_rect: Rect2) -> void:
	global_position = world_rect.position
	var live: bool = world_rect.size.x > 0.0 and world_rect.size.y > 0.0
	var emit_h: float = minf(EMIT_TOP_PX, maxf(28.0, world_rect.size.y * 0.2))
	var emit_w: float = maxf(32.0, world_rect.size.x - EDGE_INSET_PX * 2.0)
	var emit_center := Vector2(world_rect.size.x * 0.5, emit_h * 0.5)
	var emit_extents := Vector2(emit_w * 0.5, emit_h * 0.5)
	var fall_px: float = maxf(64.0, world_rect.size.y - emit_h * 0.35)
	if _snow:
		_snow.lifetime = clampf(fall_px / 150.0, 1.1, 2.4)
	if _icicles:
		_icicles.lifetime = clampf(fall_px / 200.0, 0.9, 1.9)
	for emitter in [_snow, _icicles]:
		if emitter == null:
			continue
		emitter.position = emit_center
		emitter.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		emitter.emission_rect_extents = emit_extents
		emitter.emitting = live
		if live:
			emitter.restart()


func _make_emitter(
	path: String,
	amount: int,
	lifetime: float,
	speed_min: float,
	speed_max: float,
	gravity: Vector2,
	scale_min: float,
	scale_max: float
) -> CPUParticles2D:
	var emitter := CPUParticles2D.new()
	emitter.z_as_relative = false
	emitter.z_index = 16
	emitter.amount = amount
	emitter.lifetime = lifetime
	emitter.preprocess = lifetime * 0.7
	emitter.randomness = 0.45
	emitter.explosiveness = 0.0
	emitter.local_coords = true
	emitter.direction = Vector2(0.0, 1.0)
	emitter.spread = 8.0
	emitter.gravity = gravity
	emitter.initial_velocity_min = speed_min
	emitter.initial_velocity_max = speed_max
	emitter.scale_amount_min = scale_min
	emitter.scale_amount_max = scale_max
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	fade.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.92),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	emitter.color_ramp = fade
	if path == SPARKLE_PATH or path == PUFF_PATH or path == SPARKS_PATH:
		path = SNOWFLAKE_PATH
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path) as Texture2D
		emitter.texture = tex
		if tex:
			var frames: int = maxi(1, int(tex.get_width()) / FRAME_PX)
			if frames > 1:
				var mat := CanvasItemMaterial.new()
				mat.particles_animation = true
				mat.particles_anim_h_frames = frames
				mat.particles_anim_v_frames = 1
				emitter.material = mat
				emitter.anim_speed_min = 8.0
				emitter.anim_speed_max = 14.0
	add_child(emitter)
	return emitter
