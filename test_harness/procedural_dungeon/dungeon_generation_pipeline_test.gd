extends Node

func _ready() -> void:
	if not _run_suite():
		return
	print("Dungeon generation pipeline test passed")
	get_tree().quit(0)


func _run_suite() -> bool:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager == null or not manager.has_method("generate_dungeon_contract"):
		return _fail("pipeline: DungeonGenerationManager missing")

	if not manager.has_method("pipeline"):
		return _fail("pipeline: state machine missing")
	var pipeline: Node = manager.call("pipeline") as Node
	if pipeline == null:
		return _fail("pipeline: state machine missing")

	var states_seen: Array[String] = []
	var on_state := func(from_name: String, to_name: String) -> void:
		states_seen.append(to_name)
	if pipeline.has_signal("state_changed"):
		pipeline.state_changed.connect(on_state)

	var bus_states: Array[int] = []
	var on_bus := func(state: int) -> void:
		bus_states.append(state)
	if not SignalBus.dungeon_generation_state_changed.is_connected(on_bus):
		SignalBus.dungeon_generation_state_changed.connect(on_bus)

	var requested: Array = [false]
	var on_requested := func(_request_id: String, _peer: int) -> void:
		requested[0] = true
	if not SignalBus.dungeon_generation_requested.is_connected(on_requested):
		SignalBus.dungeon_generation_requested.connect(on_requested)

	var bad: Dictionary = manager.generate_dungeon_contract({
		"requestId": "pipeline-invalid",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 2, "y": 2},
		"generationBounds": {
			"origin": {"x": 0, "y": 0},
			"size": {"x": 24, "y": 24}
		}
	}, 1)
	if bad.get("ok", false):
		return _fail("pipeline: equal start/exit must fail")
	if int(manager.generation_state) != DungeonGenerationTypes.GenerationLifecycleState.REJECTED:
		return _fail("pipeline: invalid request must end REJECTED")

	var response: Dictionary = manager.generate_dungeon_contract({
		"requestId": "pipeline-ok",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {
			"origin": {"x": 0, "y": 0},
			"size": {"x": 24, "y": 24}
		}
	}, 1)
	if not response.get("ok", false):
		return _fail("pipeline: valid request failed %s" % response)
	if int(manager.generation_state) != DungeonGenerationTypes.GenerationLifecycleState.COMMITTED:
		return _fail("pipeline: success must end COMMITTED")
	if not bool(requested[0]):
		return _fail("pipeline: dungeon_generation_requested must fire")
	if not states_seen.has("ValidateRequest"):
		return _fail("pipeline: missing ValidateRequest state")
	if not states_seen.has("GenerateLayout"):
		return _fail("pipeline: missing GenerateLayout state")
	if not states_seen.has("PopulateSpawns"):
		return _fail("pipeline: missing PopulateSpawns state")
	if not states_seen.has("ValidateLayout"):
		return _fail("pipeline: missing ValidateLayout state")
	if not states_seen.has("CommitWorld"):
		return _fail("pipeline: missing CommitWorld state")
	if not states_seen.has("Succeeded"):
		return _fail("pipeline: missing Succeeded state")
	if not bus_states.has(DungeonGenerationTypes.GenerationLifecycleState.GENERATING_LAYOUT):
		return _fail("pipeline: SignalBus never saw GENERATING_LAYOUT")
	if not bus_states.has(DungeonGenerationTypes.GenerationLifecycleState.COMMITTED):
		return _fail("pipeline: SignalBus never saw COMMITTED")

	var current: Node = pipeline.get("current_state")
	if current == null or str(current.get("name")) != "Succeeded":
		return _fail("pipeline: current state want Succeeded")

	return true


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
