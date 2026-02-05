class_name ItemEffectUnlockFireball extends ItemEffect

@export var fantasy_amount: int = 50
@export var sound: AudioStream

func use() -> void:
	print("used unlock fireball")
	DmManager.update_fantasy_level(fantasy_amount)
	DmManager.unlock("fireball")
