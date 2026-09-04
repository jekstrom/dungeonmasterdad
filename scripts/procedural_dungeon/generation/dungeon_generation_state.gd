extends Node

var machine
var _next

func init() -> void:
	pass

func Enter() -> void:
	pass

func Exit() -> void:
	pass

func Process(_delta: float):
	return next_state()

func Physics(_delta: float):
	return null

func HandleInput(_event: InputEvent):
	return null

func next_state():
	return _next

func is_terminal() -> bool:
	return false

func state_name() -> String:
	return name

func lifecycle_state() -> int:
	return DungeonGenerationTypes.GenerationLifecycleState.RECEIVED

func context():
	return machine.context

func host() -> Node:
	return machine.manager as Node

func go_to(state) -> void:
	_next = state

func reject(error_code: String, message: String) -> void:
	context().set_error(error_code, message)
	_next = machine.rejected

func reject_from(error: Dictionary) -> void:
	context().set_error_from(error)
	_next = machine.rejected

func retry_or_reject(error: Dictionary) -> void:
	var ctx = context()
	ctx.set_error_from(error)
	ctx.attempt_index += 1
	if ctx.attempt_index >= DungeonConstants.MAX_GENERATION_ATTEMPTS:
		_next = machine.rejected
	else:
		_next = machine.generate_layout
