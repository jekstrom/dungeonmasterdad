extends Control

## Thin drawer owned by MinimapWidget — paints the inset map grid.

var _owner_widget: Control


func bind_owner(owner_widget: Control) -> void:
	_owner_widget = owner_widget
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	if _owner_widget != null and _owner_widget.has_method("paint_map"):
		_owner_widget.call("paint_map", self)
