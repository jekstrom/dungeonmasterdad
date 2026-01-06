class_name ItemEffectHeal extends ItemEffect

@export var heal_amount: int = 1
@export var sound: AudioStream

func use() -> void:
	print("used")
	DmManager.update_fantasy_level(50)
