class_name ItemEffectShadowZone extends ItemEffect

@export var fantasy_amount: int = 5
@export var sound: AudioStream

# Shadow zone is the effect where each player gains a 'shadow' 
# and begins moving automatically, essentially becoming snake game
# Each item they pick up adds another shadow to their tail
# if a player hits a shadow (their own or another player's) then
# they lose Reality points and they start over with no items (one-of items drop)


func use() -> void:
	print("shadow zone enabled")
	DmManager.update_fantasy_level(fantasy_amount)
	DmManager.unlock("shadow_zone")
 
