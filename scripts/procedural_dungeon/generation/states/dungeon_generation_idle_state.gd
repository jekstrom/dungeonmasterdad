extends "res://scripts/procedural_dungeon/generation/dungeon_generation_state.gd"

func is_terminal() -> bool:
	return true

func lifecycle_state() -> int:
	return DungeonGenerationTypes.GenerationLifecycleState.RECEIVED

func Enter() -> void:
	_next = null
