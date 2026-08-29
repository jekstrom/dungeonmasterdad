class_name BajaBoss extends Enemy

## US-017 T001/T002: Baja Blast boss at dungeon exit.
## Host HP, dies via enemy.gd (T003 combat states not here; T004 unlock/can not here).
## Sheet: monsters/baja_boss.png 384x640, 128x128 cells, hframes=3 vframes=5 (SHA 1ff8b3b).
## Col 0 South, col 1 North, col 2 East. Flip E for West via Enemy.SetDirection.
## Row 0 idle, 1 wander, 2 attack, 3 blast, 4 die. Frame index = row*3 + col.
## Do not use pickups/bajablast/bajablast.png. Do not stretch a goblin.

const FALLBACK_CLIP := "idle_down"

func _init() -> void:
	max_hp = 12
	hp = 12
	aggro_faction = AggroFaction.DM


func _ready() -> void:
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2.ONE
		sprite.region_enabled = false
	super._ready()


func UpdateAnimation(state: String) -> void:
	# Map idle/wander/attack/blast/die onto the 3x5 S/N/E grid.
	# Missing clips fall back to south idle. Skip replay of the same clip (US-005 367a7f0).
	if animation_player == null:
		return
	var clip := "%s_%s" % [state, AnimDirection()]
	if not animation_player.has_animation(clip):
		clip = FALLBACK_CLIP
	if clip.is_empty() or not animation_player.has_animation(clip):
		return
	if animation_player.current_animation == clip:
		return
	animation_player.play(clip)
