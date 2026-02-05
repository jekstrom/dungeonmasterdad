class_name Shadow extends Node2D

@export var num_shadows: int = 3
@export var shadow_offset: int = 17
@export var texture: AtlasTexture
@export var main_sprite: Sprite2D

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass
	#var additional_shadows: int = clamp(num_shadows - (get_children().size()), 0, num_shadows)
	#for i in range(0, additional_shadows):
		#print("adding shadows: ", i)
		#var shadow_sprite = Sprite2D.new()
		#shadow_sprite.texture = main_sprite.texture
		#shadow_sprite.hframes = main_sprite.hframes
		#shadow_sprite.vframes = main_sprite.vframes
		#shadow_sprite.frame = main_sprite.frame
		#shadow_sprite.flip_h = main_sprite.flip_h
		#shadow_sprite.flip_v = main_sprite.flip_v
		#shadow_sprite.position += Vector2((i + 1) * shadow_offset, -5)
		#shadow_sprite.modulate = Color(0.30, 0.30, 0.30, (1 / (float(i + 1) * 0.1)))
		#shadow_sprite.name = "shadow_" + str(i)
		#add_child(shadow_sprite)
	
	#for shadow_sprite in get_children().filter(is_shadow): 
		#shadow_sprite.hframes = main_sprite.hframes
		#shadow_sprite.vframes = main_sprite.vframes
		#shadow_sprite.frame = main_sprite.frame
		#shadow_sprite.flip_h = main_sprite.flip_h
		#shadow_sprite.flip_v = main_sprite.flip_v
		#shadow_sprite.scale.x =  main_sprite.scale.x

func is_shadow(c) -> bool:
	return c.name.contains("shadow_")
