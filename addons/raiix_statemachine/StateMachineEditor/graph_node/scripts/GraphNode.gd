extends Control

signal picked_up(node)
signal picked_down(node)
signal pressed(node)

export(Vector2) var offset = Vector2.ZERO setget _on_set_offset
func _on_set_offset(v):
	offset = v
	update_rect_position()

onready var panel = $Panel
onready var panel_stylebox = panel.get_stylebox("panel") as StyleBoxFlat

var graph_edit:Control

var picking:bool = false

var selected:bool = false

func _ready():
	panel_stylebox = panel_stylebox.duplicate()
	panel.add_stylebox_override("panel", panel_stylebox)

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			if not picking:
				emit_signal("pressed", self)
			picking = true
			emit_signal("picked_up", self)
		if event.pressed and event.button_index == BUTTON_RIGHT:
			emit_signal("pressed", self)
		if not event.pressed and event.button_index == BUTTON_LEFT:
			picking = false
			emit_signal("picked_down", self)
		
			

#----- Public Methods -----
func update_rect_position():
	#rect_global_position = (offset - graph_edit.scroll_offset) / graph_edit.zoom + graph_edit.rect_global_position
	rect_position = offset - graph_edit.scroll_offset

func select():
	panel_stylebox.shadow_size = 5
	selected = true
	
	get_parent().move_child(self, get_parent().get_child_count()-1)

func unselect():
	panel_stylebox.shadow_size = 0
	selected = false
