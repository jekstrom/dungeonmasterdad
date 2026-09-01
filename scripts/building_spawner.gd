extends MultiplayerSpawner

const SMOKE_FACTORY_SCENE := "res://buildings/buildables/smoke_factory.tscn"
const PAPER_FACTORY_SCENE := "res://buildings/buildables/paper_factory.tscn"
const IRS_SCENE := "res://buildings/buildables/irs.tscn"
const OFFICE_MAX_SCENE := "res://buildings/buildables/office_max.tscn"

func _enter_tree():
	set_multiplayer_authority(1)

func _ready():
	set_multiplayer_authority(1)
	# Path-based registration so new buildings place/sync without editing playground.tscn.
	add_spawnable_scene(SMOKE_FACTORY_SCENE)
	add_spawnable_scene(PAPER_FACTORY_SCENE)
	add_spawnable_scene(IRS_SCENE)
	add_spawnable_scene(OFFICE_MAX_SCENE)
