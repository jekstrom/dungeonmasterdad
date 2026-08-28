class_name ItemEffectIncreaseFantasyLevel extends ItemEffect

@export var fantasy_amount: int = 6

func use() -> void:
	DmManager.update_fantasy_level(fantasy_amount)
