extends MultiplayerSpawner

const SMOKE_FACTORY_SCENE := "res://buildings/buildables/smoke_factory.tscn"
const PAPER_FACTORY_SCENE := "res://buildings/buildables/paper_factory.tscn"
const IRS_SCENE := "res://buildings/buildables/irs.tscn"
const OFFICE_MAX_SCENE := "res://buildings/buildables/office_max.tscn"

const _SPAWNABLES := [
	SMOKE_FACTORY_SCENE,
	PAPER_FACTORY_SCENE,
	IRS_SCENE,
	OFFICE_MAX_SCENE,
]

func _enter_tree():
	set_multiplayer_authority(1)
	_register_spawnables()

func _ready():
	set_multiplayer_authority(1)
	# Path-based registration so new buildings place/sync without editing playground.tscn.
	# Also run from _enter_tree so peers can receive spawns before _ready.
	_register_spawnables()

func _register_spawnables() -> void:
	for scene_path in _SPAWNABLES:
		_ensure_spawnable(scene_path)

func _ensure_spawnable(scene_path: String) -> void:
	for i in range(get_spawnable_scene_count()):
		var path := str(get_spawnable_scene(i))
		if path == scene_path or path.ends_with(scene_path.get_file()):
			return
	add_spawnable_scene(scene_path)
