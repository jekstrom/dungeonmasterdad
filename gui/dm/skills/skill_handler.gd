extends Node2D

func _ready() -> void:
	if SignalBus.unlock_skill.is_connected(_on_unlock):
		SignalBus.unlock_skill.disconnect(_on_unlock)
	if not SignalBus.unlock_skill.is_connected(_on_unlock):
		SignalBus.unlock_skill.connect(_on_unlock)

func _on_unlock(skill_name: String) -> void:
	DmManager.request_purchase("", skill_name)
