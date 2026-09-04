extends "res://scripts/procedural_dungeon/generation/dungeon_generation_state.gd"

func lifecycle_state() -> int:
	return DungeonGenerationTypes.GenerationLifecycleState.POPULATING_SPAWNS

func Enter() -> void:
	_next = null
	var ctx = context()
	var populated: Dictionary = machine.spawn_populator.populate(ctx.layout, ctx.request)
	if not populated.get("ok", false):
		retry_or_reject(populated)
		return
	ctx.layout = populated["layout"]
	go_to(machine.validate_layout)
