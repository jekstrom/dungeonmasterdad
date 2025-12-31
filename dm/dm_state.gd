class_name DmState extends Node

static var dm : DM
static var state_machine: DmStateMachine

func _ready() -> void:
	pass

func init() -> void:
	pass

func Enter() -> void:
	pass
	
func Exit() -> void:
	pass

func Process(_delta: float) -> DmState:
	return null
	
func Physics(_delta: float) -> DmState:
	return null
	
func HandleInput(_event: InputEvent) -> DmState:
	return null
