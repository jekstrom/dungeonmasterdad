extends Node

const IdleStateScript = preload("res://scripts/procedural_dungeon/generation/states/dungeon_generation_idle_state.gd")
const ValidateRequestStateScript = preload("res://scripts/procedural_dungeon/generation/states/dungeon_generation_validate_request_state.gd")
const GenerateLayoutStateScript = preload("res://scripts/procedural_dungeon/generation/states/dungeon_generation_generate_layout_state.gd")
const PopulateSpawnsStateScript = preload("res://scripts/procedural_dungeon/generation/states/dungeon_generation_populate_spawns_state.gd")
const ValidateLayoutStateScript = preload("res://scripts/procedural_dungeon/generation/states/dungeon_generation_validate_layout_state.gd")
const CommitWorldStateScript = preload("res://scripts/procedural_dungeon/generation/states/dungeon_generation_commit_world_state.gd")
const SucceededStateScript = preload("res://scripts/procedural_dungeon/generation/states/dungeon_generation_succeeded_state.gd")
const RejectedStateScript = preload("res://scripts/procedural_dungeon/generation/states/dungeon_generation_rejected_state.gd")
const LayoutBuilderScript = preload("res://scripts/procedural_dungeon/generation/dungeon_layout_builder.gd")
const SpawnPopulatorScript = preload("res://scripts/procedural_dungeon/generation/dungeon_spawn_populator.gd")
const WorldCommitterScript = preload("res://scripts/procedural_dungeon/generation/dungeon_world_committer.gd")
const ContextScript = preload("res://scripts/procedural_dungeon/generation/dungeon_generation_context.gd")

signal state_changed(from_name: String, to_name: String)
signal finished(ok: bool)

var manager: Node
var context
var prev_state
var current_state

var idle
var validate_request
var generate_layout
var populate_spawns
var validate_layout
var commit_world
var succeeded
var rejected

var layout_builder = LayoutBuilderScript.new()
var spawn_populator = SpawnPopulatorScript.new()
var world_committer = WorldCommitterScript.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED


func initialize(host: Node) -> void:
	manager = host
	world_committer.host = host
	idle = _make_state(IdleStateScript, "Idle")
	validate_request = _make_state(ValidateRequestStateScript, "ValidateRequest")
	generate_layout = _make_state(GenerateLayoutStateScript, "GenerateLayout")
	populate_spawns = _make_state(PopulateSpawnsStateScript, "PopulateSpawns")
	validate_layout = _make_state(ValidateLayoutStateScript, "ValidateLayout")
	commit_world = _make_state(CommitWorldStateScript, "CommitWorld")
	succeeded = _make_state(SucceededStateScript, "Succeeded")
	rejected = _make_state(RejectedStateScript, "Rejected")
	for state in [idle, validate_request, generate_layout, populate_spawns, validate_layout, commit_world, succeeded, rejected]:
		state.init()
	change_state(idle)


func run(payload: Dictionary, requester_peer_id: int) -> Dictionary:
	context = ContextScript.new()
	context.payload = payload
	context.requester_peer_id = requester_peer_id
	change_state(validate_request)
	var guard: int = 0
	while current_state != null and not current_state.is_terminal() and guard < 256:
		var nxt = current_state.next_state()
		if nxt == null:
			break
		change_state(nxt)
		guard += 1
	if current_state == null or not current_state.is_terminal():
		if context.result.is_empty() or not context.result.has("ok"):
			context.set_error(
				DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE,
				"Generation pipeline stalled"
			)
		change_state(rejected)
	finished.emit(bool(context.result.get("ok", false)))
	return context.result


func change_state(new_state) -> void:
	if new_state == null:
		return
	var from_name: String = ""
	if current_state:
		from_name = current_state.state_name()
		current_state.Exit()
	prev_state = current_state
	current_state = new_state
	if manager:
		manager.generation_state = current_state.lifecycle_state()
	state_changed.emit(from_name, current_state.state_name())
	SignalBus.dungeon_generation_state_changed.emit(current_state.lifecycle_state())
	current_state.Enter()


func _make_state(script: Script, state_name: String):
	var state = script.new()
	state.name = state_name
	state.machine = self
	add_child(state)
	return state
