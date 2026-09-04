extends "res://scripts/procedural_dungeon/generation/dungeon_generation_state.gd"

func lifecycle_state() -> int:
	return DungeonGenerationTypes.GenerationLifecycleState.GENERATING_LAYOUT

func Enter() -> void:
	_next = null
	var ctx = context()
	var seed: int = machine.layout_builder.seed_for(ctx.request, ctx.attempt_index)
	var built: Dictionary = machine.layout_builder.build(ctx.request, seed)
	if not built.get("ok", false):
		retry_or_reject(built)
		return
	ctx.layout = built["layout"]
	go_to(machine.populate_spawns)
