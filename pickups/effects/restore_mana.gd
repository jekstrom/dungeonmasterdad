class_name ItemEffectRestoreMana extends ItemEffect

@export var mana_amount: int = 25

func use() -> void:
	DmManager.add_mana(mana_amount)
