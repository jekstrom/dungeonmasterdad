class_name DungeonGenerationTypes extends RefCounted

enum GenerationLifecycleState {
	RECEIVED,
	VALIDATED,
	GENERATING_LAYOUT,
	VALIDATED_LAYOUT,
	POPULATING_SPAWNS,
	COMMITTED,
	REJECTED
}

const FAILURE_INVALID_REQUEST: String = "INVALID_REQUEST"
const FAILURE_POSITION_OUT_OF_BOUNDS: String = "POSITION_OUT_OF_BOUNDS"
const FAILURE_POSITION_NOT_PLACEABLE: String = "POSITION_NOT_PLACEABLE"
const FAILURE_START_EQUALS_EXIT: String = "START_EQUALS_EXIT"
const FAILURE_LAYOUT_INFEASIBLE: String = "LAYOUT_INFEASIBLE"
const FAILURE_AUTHORITY_VIOLATION: String = "AUTHORITY_VIOLATION"
const FAILURE_SESSION_CONFLICT: String = "SESSION_CONFLICT"
const FAILURE_BOUNDS_TOO_SMALL: String = "BOUNDS_TOO_SMALL"

static func failure_codes() -> PackedStringArray:
	return PackedStringArray([
		FAILURE_INVALID_REQUEST,
		FAILURE_POSITION_OUT_OF_BOUNDS,
		FAILURE_POSITION_NOT_PLACEABLE,
		FAILURE_START_EQUALS_EXIT,
		FAILURE_LAYOUT_INFEASIBLE,
		FAILURE_AUTHORITY_VIOLATION,
		FAILURE_SESSION_CONFLICT,
		FAILURE_BOUNDS_TOO_SMALL
	])

static func is_valid_failure_code(error_code: String) -> bool:
	return failure_codes().has(error_code)


static func error_payload(request_id: String, error_code: String, message: String) -> Dictionary:
	return {
		"ok": false,
		"requestId": request_id,
		"error_code": error_code,
		"code": error_code,
		"message": message
	}


static func lifecycle_name(state: int) -> String:
	match state:
		GenerationLifecycleState.RECEIVED:
			return "received"
		GenerationLifecycleState.VALIDATED:
			return "validated"
		GenerationLifecycleState.GENERATING_LAYOUT:
			return "generating_layout"
		GenerationLifecycleState.VALIDATED_LAYOUT:
			return "validated_layout"
		GenerationLifecycleState.POPULATING_SPAWNS:
			return "populating_spawns"
		GenerationLifecycleState.COMMITTED:
			return "committed"
		GenerationLifecycleState.REJECTED:
			return "rejected"
		_:
			return "unknown"
