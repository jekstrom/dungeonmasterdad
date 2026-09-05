class_name PlayerStateMachine extends Node

var states: Array[PlayerState] = []
var prev_state: PlayerState = null
var current_state: PlayerState = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	
func Initialize(_player: Player) -> void:
	if !is_multiplayer_authority(): return
	
	states = []
	
	for c in get_children():
		if c is PlayerState:
			states.append(c)
	
	if states.size() == 0:
		return
	
	states[0].player = _player
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

func ChangeState(new_state: PlayerState) -> void:
	if new_state == null || new_state == current_state:
		return
	if current_state:
		current_state.Exit()
		
	prev_state = current_state
	current_state = new_state
	current_state.Enter()

@rpc("any_peer", "call_local", "reliable")
func RequestChangeStateTo(state_name: String) -> void:
	if !multiplayer.is_server(): return
	ChangeStateTo.rpc(state_name)
	
@rpc("any_peer", "call_local", "reliable")
func ChangeStateTo(state_name: String) -> void:
	for i in range(0, states.size()):
		if states[i].name == state_name:
			ChangeState(states[i])
			return
