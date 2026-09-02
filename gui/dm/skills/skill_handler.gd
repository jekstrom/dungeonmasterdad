extends Node2D

func _ready() -> void:
	SignalBus.unlock_skill.connect(_on_unlock)

func _on_unlock(skill_name: String) -> void:
	print(skill_name, "Unlocked")
	DmManager.unlock(skill_name)
