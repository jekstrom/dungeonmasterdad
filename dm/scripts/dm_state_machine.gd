class_name DmStateMachine extends Node

var states: Array[DmState] = []
var prev_state: DmState = null
var current_state: DmState = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	
func Initialize(_dm: DM) -> void:
	states = []
	
	for c in get_children():
		if c is DmState:
			states.append(c)
	
	if states.size() == 0:
		return
	
	states[0].dm = _dm
	states[0].state_machine = self
	
	for state in states:
		state.init()
	
	ChangeState(states[0])
	process_mode = Node.PROCESS_MODE_INHERIT

func _process(delta: float) -> void:
	ChangeState(current_state.Process(delta))
	
func _physics_process(delta: float) -> void:
	ChangeState(current_state.Physics(delta))

func _unhandled_input(event: InputEvent) -> void:
	ChangeState(current_state.HandleInput(event))

func ChangeState(new_state: DmState) -> void:
	if new_state == null || new_state == current_state:
		return
	if current_state:
		current_state.Exit()
		
	prev_state = current_state
	current_state = new_state
	current_state.Enter()
