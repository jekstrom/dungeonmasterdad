extends "res://scripts/procedural_dungeon/generation/dungeon_generation_state.gd"

func lifecycle_state() -> int:
	return DungeonGenerationTypes.GenerationLifecycleState.VALIDATED_LAYOUT

func Enter() -> void:
	_next = null
	var ctx = context()
	var committed: Dictionary = machine.world_committer.commit(ctx.layout)
	if not committed.get("ok", false):
		reject_from(committed)
		return
	go_to(machine.succeeded)
