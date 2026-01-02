extends CanvasLayer

func _ready() -> void:
	turn_off()

func turn_on() -> void:
	self.visible = true
	
func turn_off() -> void:
	self.visible = false
