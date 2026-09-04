extends RefCounted

var payload: Dictionary = {}
var requester_peer_id: int = 1
var request: DungeonGenerationRequest
var layout: DungeonLayoutData
var result: Dictionary = {}
var last_error: Dictionary = {}
var attempt_index: int = 0
var session_acquired: bool = false


func request_id() -> String:
	if request != null:
		return request.request_id
	return str(payload.get("requestId", payload.get("request_id", "")))


func set_error(error_code: String, message: String, id: String = "") -> void:
	var rid: String = id
	if rid.is_empty():
		rid = request_id()
	result = DungeonGenerationTypes.error_payload(rid, error_code, message)
	last_error = result


func set_error_from(error: Dictionary) -> void:
	var rid: String = str(error.get("requestId", error.get("request_id", request_id())))
	var code: String = str(error.get("error_code", error.get("code", DungeonGenerationTypes.FAILURE_INVALID_REQUEST)))
	var message: String = str(error.get("message", "Generation failed"))
	set_error(code, message, rid)


func set_success(layout_data: DungeonLayoutData) -> void:
	layout = layout_data
	result = {
		"ok": true,
		"requestId": layout_data.request_id,
		"data": layout_data.to_contract_dictionary()
	}
