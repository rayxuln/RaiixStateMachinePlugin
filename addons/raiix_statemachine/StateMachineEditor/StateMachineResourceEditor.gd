tool
extends Control


onready var create_node_menu = $CreateNodeMenu
onready var graph_edit_container = $GraphEditContainer
onready var graph_edit = $GraphEditContainer/GraphEdit
onready var info_container = $InfoContainer
onready var info_label = $InfoContainer/VBoxContainer/InfoLabel

var arrow_placing_start_node = null

var icon_tex = preload("../images/edit_icon.png")

var state_machine:StateMachine = null

var editor_plugin:EditorPlugin = null

func _ready():
	info_container.visible = true
	graph_edit_container.visible = false

#----- Methods -----
func handle_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_RIGHT:
			if graph_edit.arrow_placing_mode:
				graph_edit.cancel_arrow_placing()
			else:
				popup_create_node_menu()
		elif event.pressed and event.button_index == BUTTON_LEFT:
			if graph_edit.arrow_placing_mode and graph_edit.arrow_placing_hovering_node == null:
				arrow_placing_start_node = graph_edit.arrow_placing_start_node
				graph_edit.cancel_arrow_placing()
				popup_create_node_menu()

func popup_create_node_menu():
	create_node_menu.set_global_position(get_global_mouse_position())
	create_node_menu.popup()
	yield(get_tree(), "idle_frame")
	detect_create_node_menu_item_enable_or_not()

func detect_create_node_menu_item_enable_or_not():
	create_node_menu.set_item_disabled(create_node_menu.get_item_index(1), graph_edit.selection.size() == 0)
	create_node_menu.set_item_disabled(create_node_menu.get_item_index(2), graph_edit.selection.size() == 0 or not (graph_edit.selection.size()==1 and graph_edit.selection[0].has_method("graph_node_type")))

func select_state_machine_node(sm):
	state_machine = sm
	if state_machine.state_machine_resource == null:
		info_label.text = "Push the button to create a state machine resource!"
		info_container.visible = true
		graph_edit_container.visible = false
	else:
		info_container.visible = false
		graph_edit_container.visible = true

func refresh_inspector():
	editor_plugin.get_editor_interface().get_inspector().refresh()
#----- Undo Redo -----


#----- Signals -----

func _on_GraphEdit_gui_input(event):
	handle_gui_input(event)

func _on_GraphEdit_node_gui_input(event, node):
	handle_gui_input(event)

func _on_CreateNodeMenu_id_pressed(id):
	if id == 0:
		var n = preload("./graph_node/GraphNode.tscn").instance()
		graph_edit.add_node(n)
		n.tip_text = ""
		n.text = "UnkownState"
		n.offset = graph_edit.nodes.get_local_mouse_position() + graph_edit.scroll_offset
		
		if arrow_placing_start_node:
			graph_edit.connect_nodes(arrow_placing_start_node, n)
			arrow_placing_start_node = null
	if id == 1:#delete
		for n in graph_edit.selection:
			graph_edit.remove_node(n)
	if id == 2:#add transition
		assert(graph_edit.selection.size() > 0)
		graph_edit.place_arrow(graph_edit.selection[0])
		


func _on_GraphEdit_connect_node_request(start_node, end_node):
	if not graph_edit.check_is_node_connected(start_node, end_node):
		graph_edit.connect_nodes(start_node, end_node)
	else:
		printerr("%s aleady connected with %s!" % [start_node.name, end_node.name])


func _on_CreateSMRButton_pressed():
	if not state_machine.state_machine_resource:
		state_machine.state_machine_resource = StateMachineResource.new()
	refresh_inspector()
	select_state_machine_node(state_machine)
