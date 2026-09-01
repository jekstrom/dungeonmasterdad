@tool
class_name SkillTreeDoodad extends Node2D

const SKILL_HINT_RANGE := 72.0

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var skill_hitbox: Area2D = $Area2D
@onready var label: Label = $Control/FlowContainer/Label

func _enter_tree() -> void:
	y_sort_enabled = true
	z_index = 0

func _ready() -> void:
	add_to_group("skill_trees")
	skill_hitbox.body_entered.connect(_on_enter)
	skill_hitbox.body_exited.connect(_on_exit)
	DmManager.interact_pressed.connect(_on_interact)
	label.text = ""

func _on_enter(_body: Node2D) -> void:
	if _body is DM and _body.is_multiplayer_authority():
		label.text = "F"
	else:
		label.text = "NOOOO"
		
func _on_exit(_body: Node2D) -> void:
	if _body is DM and _body.is_multiplayer_authority():
		label.text = ""
		
func _on_interact() -> void:
	if label.text == "F":
		print("interacted")
		DmManager._show_skill_tree_hud()
		
func _make_interact_marker() -> Control:
	var root := Label.new()
	root.name = "InteractHint"
	root.text = "F"
	root.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	root.size = Vector2(36, 20)
	root.add_theme_font_size_override("font_size", 14)
	root.add_theme_color_override("font_color", Color(1, 1, 0.75, 1))
	root.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	root.add_theme_constant_override("outline_size", 6)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.visible = false
	return root
	
func _update_texture() -> void:
	if not _resolve_sprite():
		return
	sprite_2d.position = Vector2.ZERO
	if not sprite_2d.texture is AtlasTexture:
		return

func _resolve_sprite() -> bool:
	if sprite_2d:
		return true
	sprite_2d = get_node_or_null("Sprite2D")
	return sprite_2d != null

func is_skill_prompt_target(striker: Node) -> bool:
	if not can_skill(striker):
		return false
	if not (striker is Node2D):
		return false
	var body: Node2D = striker as Node2D
	if body.global_position.distance_to(global_position) > SKILL_HINT_RANGE:
		return false
	return false
	
func can_skill(striker: Node) -> bool:
	return false
	
func in_interact_range(player: Node2D) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	return player.global_position.distance_to(global_position) <= SKILL_HINT_RANGE
