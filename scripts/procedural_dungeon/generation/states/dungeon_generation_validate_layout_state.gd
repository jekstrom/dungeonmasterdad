extends "res://scripts/procedural_dungeon/generation/dungeon_generation_state.gd"

func lifecycle_state() -> int:
	return DungeonGenerationTypes.GenerationLifecycleState.VALIDATED_LAYOUT

func Enter() -> void:
	_next = null
	var ctx = context()
	var checked: Dictionary = machine.spawn_populator.validate_populated(ctx.layout)
	if not checked.get("ok", false):
		retry_or_reject(checked)
		return
	go_to(machine.commit_world)
