class_name ItemEffectCoal extends ItemEffect

@export var fantasy_amount: int = 5
@export var sound: AudioStream

func use() -> void:
	pass
	#print("used unlock fireball")
	#DmManager.update_fantasy_level(fantasy_amount)
	#DmManager.unlock_fireball()
