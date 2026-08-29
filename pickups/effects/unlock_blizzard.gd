class_name ItemEffectUnlockBlizzard extends ItemEffect

func use() -> void:
	DmManager.unlock("bemidji_blizzard")
