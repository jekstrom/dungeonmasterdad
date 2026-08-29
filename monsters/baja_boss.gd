class_name BajaBoss extends Enemy

## US-017 T001/T002: Baja Blast boss at dungeon exit.
## South placeholder until the full idle/wander/attack/blast/die × S/N/E sheet is wired.
## Sheet is 3×5 of 128px cells (S/N/E × idle/wander/attack/blast/die); this slice stays on frame 0.
## Do not use pickups/bajablast/bajablast.png as the body. Combat states are T003.

const PLACEHOLDER_CLIP := "idle_down"

func _init() -> void:
	max_hp = 12
	hp = 12
	aggro_faction = AggroFaction.DM


func _ready() -> void:
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	super._ready()


func AnimDirection() -> String:
	# Missing N/E/W stay south until those columns are consumed by T003.
	return "down"


func UpdateAnimation(state: String) -> void:
	# Wander/walk/attack/blast all use the south placeholder this slice.
	# Do not restart the same clip every tick (US-005 367a7f0 flicker lesson).
	if animation_player == null:
		return
	var clip := _placeholder_clip(state)
	if animation_player.current_animation == clip:
		return
	animation_player.play(clip)


func _placeholder_clip(state: String) -> String:
	var south := "%s_down" % state
	if animation_player.has_animation(south):
		# Still south-only; walk_down is authored as frame 0.
		return south
	if animation_player.has_animation(PLACEHOLDER_CLIP):
		return PLACEHOLDER_CLIP
	if animation_player.has_animation("RESET"):
		return "RESET"
	return ""
