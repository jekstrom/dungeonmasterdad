extends Node
## US-059: wizard sheets 512×384, live texture ≠ PlayerSprite02, idle/walk/attack/cast clips.

const SHEETS := [
	"res://dm/sprites/dm_idle.png",
	"res://dm/sprites/dm_walk.png",
	"res://dm/sprites/dm_attack.png",
	"res://dm/sprites/dm_cast.png",
]

const CLIPS := [
	"idle_down", "idle_side", "idle_up",
	"walk_down", "walk_side", "walk_up",
	"attack_down", "attack_side", "attack_up",
	"cast_down", "cast_side", "cast_up",
]

func _ready() -> void:
	for path in SHEETS:
		if not ResourceLoader.exists(path):
			return _fail("US-059: missing sheet %s" % path)
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img == null:
			var tex := load(path) as Texture2D
			if tex == null:
				return _fail("US-059: cannot load %s" % path)
			if tex.get_width() != 512 or tex.get_height() != 384:
				return _fail("US-059: %s must be 512×384, got %dx%d" % [path, tex.get_width(), tex.get_height()])
		else:
			if img.get_width() != 512 or img.get_height() != 384:
				return _fail("US-059: %s must be 512×384, got %dx%d" % [path, img.get_width(), img.get_height()])

	var dm_scene: PackedScene = load("res://dm/dm.tscn") as PackedScene
	if dm_scene == null:
		return _fail("US-059: dm.tscn missing")
	var dm: Node = dm_scene.instantiate()
	add_child(dm)
	await get_tree().process_frame

	var spr: Sprite2D = dm.get_node_or_null("Sprite2D") as Sprite2D
	if spr == null or spr.texture == null:
		return _fail("US-059: Sprite2D/texture missing")
	var live := str(spr.texture.resource_path)
	if live.find("PlayerSprite02") != -1:
		return _fail("US-059: live texture must not be PlayerSprite02, got %s" % live)
	if live.find("dm_idle.png") == -1 and live.find("dm_walk.png") == -1 and live.find("dm_attack.png") == -1 and live.find("dm_cast.png") == -1:
		return _fail("US-059: live texture should be a dm_*.png sheet, got %s" % live)
	if spr.hframes != 4 or spr.vframes != 3:
		return _fail("US-059: Sprite2D must be hframes=4 vframes=3, got %d×%d" % [spr.hframes, spr.vframes])

	var ap: AnimationPlayer = dm.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if ap == null:
		return _fail("US-059: AnimationPlayer missing")
	for clip in CLIPS:
		if not ap.has_animation(clip):
			return _fail("US-059: missing AnimationPlayer clip %s" % clip)

	# Cast while targeting: setup_targeting should switch to cast sheet.
	if not dm.has_method("setup_targeting") or not dm.has_method("update_animation"):
		return _fail("US-059: DM missing targeting/update_animation")
	# Targeting scene may be null in headless — call update_animation("cast") directly.
	dm.call("update_animation", "cast")
	await get_tree().process_frame
	var cast_tex := str((dm.get_node("Sprite2D") as Sprite2D).texture.resource_path)
	if cast_tex.find("dm_cast.png") == -1:
		return _fail("US-059: update_animation(cast) must use dm_cast.png, got %s" % cast_tex)
	var anim_name := str((dm.get_node("AnimationPlayer") as AnimationPlayer).current_animation)
	if not anim_name.begins_with("cast_"):
		return _fail("US-059: cast anim not playing, got %s" % anim_name)

	dm.call("update_animation", "idle")
	await get_tree().process_frame
	var idle_tex := str((dm.get_node("Sprite2D") as Sprite2D).texture.resource_path)
	if idle_tex.find("dm_idle.png") == -1:
		return _fail("US-059: idle must use dm_idle.png, got %s" % idle_tex)

	# Scale flip contract still present
	if not dm.has_method("apply_aim"):
		return _fail("US-059: apply_aim missing")
	dm.call("apply_aim", Vector2.LEFT)
	if absf((dm.get_node("Sprite2D") as Sprite2D).scale.x + 1.0) > 0.01:
		return _fail("US-059: left aim must set scale.x = -1")

	print("US-059 dm wizard sheet test passed")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
