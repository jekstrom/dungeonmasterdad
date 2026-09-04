extends "res://scripts/procedural_dungeon/generation/dungeon_generation_state.gd"

func is_terminal() -> bool:
	return true

func lifecycle_state() -> int:
	return DungeonGenerationTypes.GenerationLifecycleState.REJECTED

func Enter() -> void:
	_next = null
	var ctx = context()
	if ctx.result.is_empty() or bool(ctx.result.get("ok", false)):
		if not ctx.last_error.is_empty():
			ctx.set_error_from(ctx.last_error)
		else:
			ctx.set_error(DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE, "Generation rejected")
	if ctx.session_acquired:
		host().release_contract_session(false)
		ctx.session_acquired = false
