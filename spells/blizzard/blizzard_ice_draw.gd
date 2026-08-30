class_name BlizzardIceDraw extends RefCounted

const SHADER := preload("res://shaders/blizzard_ice.gdshader")
const TEX := preload("res://sprites/blizzard_overlay.png")
const TILE_PX := 128.0
const CORNER_PX := 44.0
const ICE_ALPHA := 0.4
const GLINT := 0.18
const TINT := Color(0.74, 0.93, 1.0, 1.0)


static func make_tile(cells: Vector2i, cell: Vector2i) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = TEX
	sprite.centered = true
	sprite.offset = Vector2.ZERO
	sprite.region_enabled = false
	sprite.z_as_relative = false
	sprite.z_index = 1
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("pocket_cells", Vector2(cells))
	mat.set_shader_parameter("cell_in_pocket", Vector2(cell))
	mat.set_shader_parameter("pocket_px_override", Vector2.ZERO)
	mat.set_shader_parameter("tile_px", TILE_PX)
	mat.set_shader_parameter("corner_px", CORNER_PX)
	mat.set_shader_parameter("ice_alpha", ICE_ALPHA)
	mat.set_shader_parameter("ice_tint", TINT)
	mat.set_shader_parameter("glint_strength", GLINT)
	sprite.material = mat
	sprite.set_meta("debug_claim_overlay", false)
	return sprite


static func attach_grid(parent: Node2D, top_left: Vector2, cells: Vector2i, z_index: int = 1) -> void:
	if parent == null or cells.x <= 0 or cells.y <= 0:
		return
	for y in range(cells.y):
		for x in range(cells.x):
			var sprite: Sprite2D = make_tile(cells, Vector2i(x, y))
			sprite.name = "BlizzardIce_%d_%d" % [x, y]
			sprite.z_index = z_index
			sprite.position = top_left + Vector2(float(x) + 0.5, float(y) + 0.5) * TILE_PX
			parent.add_child(sprite)
