extends Control


onready var create_node_menu = $CreateNodeMenu
onready var graph_edit = $VBoxContainer/GraphEdit


#----- Methods -----
func handle_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_RIGHT:
			create_node_menu.set_global_position(get_global_mouse_position())
			create_node_menu.popup()
			yield(get_tree(), "idle_frame")
			detect_create_node_menu_item_enable_or_not()

func detect_create_node_menu_item_enable_or_not():
	create_node_menu.set_item_disabled(create_node_menu.get_item_index(1), graph_edit.selection.size() == 0)
	create_node_menu.set_item_disabled(create_node_menu.get_item_index(2), graph_edit.selection.size() == 0 or not (graph_edit.selection.size()==1 and graph_edit.selection[0].has_method("graph_node_type")))
#----- Signals -----

func _on_GraphEdit_gui_input(event):
	handle_gui_input(event)

func _on_GraphEdit_node_gui_input(event, node):
	handle_gui_input(event)

func _on_CreateNodeMenu_id_pressed(id):
	if id == 0:
		var n = preload("./graph_nodes/TemplateGraphNode.tscn").instance()
		n = graph_edit.add_node(n)
		n.offset = graph_edit.nodes.get_local_mouse_position() + graph_edit.scroll_offset
	if id == 1:#delete
		for n in graph_edit.selection:
			graph_edit.remove_node(n)
	if id == 2:#add transition
		assert(graph_edit.selection.size() > 0)
		graph_edit.place_arrow(graph_edit.selection[0])
		


func _on_GraphEdit_connect_node_request(start_node, end_node):
	graph_edit.connect_nodes(start_node, end_node)
