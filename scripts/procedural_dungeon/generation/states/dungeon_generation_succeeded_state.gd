extends "res://scripts/procedural_dungeon/generation/dungeon_generation_state.gd"

func is_terminal() -> bool:
	return true

func lifecycle_state() -> int:
	return DungeonGenerationTypes.GenerationLifecycleState.COMMITTED

func Enter() -> void:
	_next = null
	var ctx = context()
	host().apply_committed_layout(ctx.layout)
	ctx.set_success(ctx.layout)
