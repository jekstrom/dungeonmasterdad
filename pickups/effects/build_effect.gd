class_name ItemEffectBuild extends ItemEffect

@export var heal_amount: int = 1
@export var sound: AudioStream

func use() -> void:
	print("used build")
	#PlayerManager.player.update_hitpoints(heal_amount)
	#DmManager.dm.play_audio(sound)
