extends Node

var buildings = {}

func _ready():
	load_buildings_from_folder("res://buildings/buildables/")

func load_buildings_from_folder(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var building = load(path + file_name)
				if building is BuildingData:
					buildings[building.get_path()] = building
			file_name = dir.get_next()
	
	print("BuildingDatabase: Loaded ", buildings.size(), " buildings.")

func get_building(id: String) -> BuildingData:
	if buildings.has(id):
		return buildings[id]
	return null
