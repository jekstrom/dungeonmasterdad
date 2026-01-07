class_name BuildingData extends Resource

@export var id: String = ""
@export var scene: PackedScene
@export var cost_item: String
@export var cost_qty: int
@export var size: Vector2i = Vector2i(1, 1) # Size in grid cells

const building_size: int = 100
