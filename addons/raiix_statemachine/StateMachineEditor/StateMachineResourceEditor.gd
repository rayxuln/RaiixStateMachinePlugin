extends Control


onready var create_node_menu = $CreateNodeMenu
onready var graph_edit = $VBoxContainer/GraphEdit

func _on_GraphEdit_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_RIGHT:
			create_node_menu.set_global_position(get_global_mouse_position())
			create_node_menu.popup()


func _on_CreateNodeMenu_id_pressed(id):
	if id == 0:
		var n = preload("./graph_nodes/TemplateGraphNode.tscn").instance()
		n = graph_edit.add_node(n)
		n.offset = graph_edit.get_local_mouse_position() + graph_edit.scroll_offset
