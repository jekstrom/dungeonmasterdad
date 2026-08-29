extends Node

var items = {}

func _ready():
	load_items_from_folder("res://pickups/")

func load_items_from_folder(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var item = load(path + file_name)
				if item is ItemData:
					items[item.get_path()] = item
			file_name = dir.get_next()
	
	print("ItemDatabase: Loaded ", items.size(), " items.")

func get_item(id: String) -> ItemData:
	if items.has(id):
		return items[id]
	if id.ends_with(".tres") and ResourceLoader.exists(id):
		var item = load(id)
		if item is ItemData:
			items[id] = item
			return item
	return null
