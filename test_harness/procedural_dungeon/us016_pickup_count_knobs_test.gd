extends Node

const Planner = preload("res://scripts/procedural_dungeon/pickup_spawn_planner.gd")

func _ready() -> void:
	var generator := DungeonGenerator.new()
	var payload: Dictionary = generator.to_payload()
	if int(payload.get("startRoomDewCount", -1)) != DungeonConstants.DEFAULT_START_ROOM_DEW_COUNT:
		_fail("US-016 knobs: generator default start-room Dew must be %d" % DungeonConstants.DEFAULT_START_ROOM_DEW_COUNT)
		return
	if int(payload.get("extraDewCount", -1)) != DungeonConstants.DEFAULT_EXTRA_DEW_COUNT:
		_fail("US-016 knobs: generator default extra Dew must be %d" % DungeonConstants.DEFAULT_EXTRA_DEW_COUNT)
		return
	if int(payload.get("d6Count", -1)) != DungeonConstants.DEFAULT_D6_COUNT:
		_fail("US-016 knobs: generator default d6 must be %d" % DungeonConstants.DEFAULT_D6_COUNT)
		return
	if int(payload.get("d20Count", -1)) != DungeonConstants.DEFAULT_D20_COUNT:
		_fail("US-016 knobs: generator default d20 must be %d" % DungeonConstants.DEFAULT_D20_COUNT)
		return
	generator.start_room_dew_count = 2
	generator.extra_dew_count = 1
	generator.d6_count = 3
	generator.d20_count = 0
	var tuned: Dictionary = generator.to_payload()
	if int(tuned.get("startRoomDewCount", -1)) != 2 or int(tuned.get("extraDewCount", -1)) != 1:
		_fail("US-016 knobs: generator payload must include tuned Dew counts")
		return
	if int(tuned.get("d6Count", -1)) != 3 or int(tuned.get("d20Count", -1)) != 0:
		_fail("US-016 knobs: generator payload must include tuned dice counts")
		return
	generator.free()

	var request := DungeonGenerationRequest.new()
	request.from_payload(_base_payload({
		"d6Count": 99,
		"d20Count": -4
	}))
	if request.d6_count != DungeonConstants.MAX_PICKUP_COUNT:
		_fail("US-016 knobs: d6Count must clamp to %d, got %d" % [DungeonConstants.MAX_PICKUP_COUNT, request.d6_count])
		return
	if request.d20_count != 0:
		_fail("US-016 knobs: negative d20Count must clamp to 0")
		return

	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager == null or not manager.has_method("generate_dungeon_contract"):
		_fail("US-016 knobs: DungeonGenerationManager missing")
		return

	var defaults: Dictionary = manager.generate_dungeon_contract(_base_payload({
		"requestId": "us016-pickup-knobs-default"
	}), 1)
	if not defaults.get("ok", false):
		_fail("US-016 knobs: default generation failed %s" % defaults)
		return
	var default_counts: Dictionary = _count_types(defaults.get("data", {}).get("itemPickups", []))
	if int(default_counts.get(Planner.GREEN_DEW_PATH, 0)) < Planner.START_ROOM_DEW_COUNT:
		_fail("US-016 knobs: default Dew count too low")
		return
	if int(default_counts.get(Planner.D6_PATH, 0)) != Planner.D6_COUNT:
		_fail("US-016 knobs: default d6 count expected %d" % Planner.D6_COUNT)
		return
	if int(default_counts.get(Planner.D20_PATH, 0)) != Planner.D20_COUNT:
		_fail("US-016 knobs: default d20 count expected %d" % Planner.D20_COUNT)
		return

	var custom: Dictionary = manager.generate_dungeon_contract(_base_payload({
		"requestId": "us016-pickup-knobs-custom",
		"startRoomDewCount": 2,
		"extraDewCount": 1,
		"d6Count": 3,
		"d20Count": 0
	}), 1)
	if not custom.get("ok", false):
		_fail("US-016 knobs: custom generation failed %s" % custom)
		return
	var custom_counts: Dictionary = _count_types(custom.get("data", {}).get("itemPickups", []))
	if int(custom_counts.get(Planner.GREEN_DEW_PATH, 0)) != 3:
		_fail("US-016 knobs: expected 3 Dew (2 start + 1 extra), got %d" % int(custom_counts.get(Planner.GREEN_DEW_PATH, 0)))
		return
	if int(custom_counts.get(Planner.D6_PATH, 0)) != 3:
		_fail("US-016 knobs: expected 3 d6, got %d" % int(custom_counts.get(Planner.D6_PATH, 0)))
		return
	if int(custom_counts.get(Planner.D20_PATH, 0)) != 0:
		_fail("US-016 knobs: expected 0 d20, got %d" % int(custom_counts.get(Planner.D20_PATH, 0)))
		return

	var none: Dictionary = manager.generate_dungeon_contract(_base_payload({
		"requestId": "us016-pickup-knobs-zero-dice",
		"d6Count": 0,
		"d20Count": 0
	}), 1)
	if not none.get("ok", false):
		_fail("US-016 knobs: zero-dice generation failed")
		return
	var none_counts: Dictionary = _count_types(none.get("data", {}).get("itemPickups", []))
	if int(none_counts.get(Planner.D6_PATH, 0)) != 0 or int(none_counts.get(Planner.D20_PATH, 0)) != 0:
		_fail("US-016 knobs: zero dice knobs must place no dice")
		return

	print("US-016 pickup count knobs test passed")
	get_tree().quit(0)

func _base_payload(overrides: Dictionary) -> Dictionary:
	var payload := {
		"requestId": "us016-pickup-knobs",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {
			"origin": {"x": 0, "y": 0},
			"size": {"x": 24, "y": 24}
		}
	}
	for key in overrides.keys():
		payload[key] = overrides[key]
	return payload

func _count_types(pickups: Array) -> Dictionary:
	var counts: Dictionary = {}
	for pickup in pickups:
		var item_type: String = str(pickup.get("item_type", ""))
		counts[item_type] = int(counts.get(item_type, 0)) + 1
	return counts

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
