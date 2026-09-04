extends "res://scripts/procedural_dungeon/generation/dungeon_generation_state.gd"

func lifecycle_state() -> int:
	return DungeonGenerationTypes.GenerationLifecycleState.RECEIVED

func Enter() -> void:
	_next = null
	var ctx = context()
	var request_result: Dictionary = host().validate_generation_request_payload(ctx.payload, ctx.requester_peer_id)
	if not request_result.get("ok", false):
		reject_from(request_result)
		return
	ctx.request = request_result["request"]
	host().active_request_id = ctx.request.request_id
	ctx.session_acquired = true
	host().generation_state = DungeonGenerationTypes.GenerationLifecycleState.VALIDATED
	SignalBus.dungeon_generation_requested.emit(ctx.request.request_id, ctx.request.requested_by_peer_id)
	go_to(machine.generate_layout)
