tool
extends Control


onready var create_node_menu = $CreateNodeMenu
onready var graph_edit_container = $GraphEditContainer
onready var graph_edit = $GraphEditContainer/GraphEdit
onready var info_container = $InfoContainer
onready var info_label = $InfoContainer/VBoxContainer/InfoLabel
onready var path_button_container = $GraphEditContainer/HBoxContainer/PathButtonContainer

var arrow_placing_start_node = null

var icon_tex = preload("../images/edit_icon.png")

var state_machine:StateMachine = null
var sm_resource:StateMachineResource setget , _on_get_sm_resource
func _on_get_sm_resource():
	return state_machine.state_machine_resource

var editor_plugin:EditorPlugin = null

onready var ur_lib = preload("./undo_redo_lib.gd").new(self)

func _ready():
	info_container.visible = true
	graph_edit_container.visible = false

#----- Methods -----
func handle_gui_input(event):
	if event is InputEventMouseButton:
		ur_lib.ur_just_dirty_the_editor()
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
		
		self.sm_resource	.block_written = true
		graph_edit.zoom = self.sm_resource.zoom
		graph_edit.scroll_offset = self.sm_resource.scroll_offset
		self.sm_resource	.block_written = false
		generate_nodes_and_connections_with_resource()
		generate_path_buttons_from_path(self.sm_resource.path)

func add_path_button(n, path):
	var b = Button.new()
	path_button_container.add_child(b)
	b.name = n
	b.text = n
	b.set_meta("path", path)
	b.connect("pressed", self, "_on_path_button_pressed", [b])

func add_seperator():
	var s = VSeparator.new()
	path_button_container.add_child(s)

func clear_path_button_caintainer():
	if path_button_container.get_child_count() == 0:
		return
	var cs = []
	for c in path_button_container.get_children():
		cs.append(c)
	for c in cs:
		c.queue_free()

func generate_path_buttons_from_path(path:String):
	clear_path_button_caintainer()
	add_path_button('root', '/')
	var ss = path.split('/')
	var temp = '/'
	for s in ss:
		if not s.empty():
			temp += '/' + s
			add_seperator()
			add_path_button(s, temp)

func refresh_inspector():
	editor_plugin.get_editor_interface().get_inspector().refresh()

func generate_nodes_and_connections_with_resource():
	var sm_data = self.sm_resource.current
	
	graph_edit.clear_all_nodes()
	
	# gen nodes
	for node_data in sm_data.states:
		var n = preload("./graph_node/GraphNode.tscn").instance()
		graph_edit.add_node(n)
		n.tip_text = "Init" if node_data.init else ""
		n.name = node_data.name
		n.text = node_data.name
		n.offset = node_data.offset
		n.data = node_data
		n.right_button_tex = icon_tex if node_data.sub_state_machine else null
	
	# connect nodes
	for arrow_data in sm_data.transitions:
		var from = graph_edit.nodes.get_node_or_null(arrow_data.from)
		var to = graph_edit.nodes.get_node_or_null(arrow_data.to)
		
		graph_edit.connect_nodes(from, to, arrow_data)
	
	graph_edit.target_zoom = graph_edit.zoom

func add_state_node(pos):
	var data = self.sm_resource.gen_state_data()
	var n = preload("./graph_node/GraphNode.tscn").instance()
	graph_edit.add_node(n)
	n.tip_text = "Init" if data.init else ""
	n.name = data.name
	data.name = n.name
	n.text = data.name
	n.data = data
	n.offset = pos
	self.sm_resource.current.states.append(data)
	return n

func connect_nodes(start_node, end_node):
	var data = self.sm_resource.gen_transition_data()
	graph_edit.connect_nodes(start_node, end_node, data)
	self.sm_resource.current.transitions.append(data)
	

func remove_node(node:Control):
	if node.has_method("graph_node_type"):
		self.sm_resource.current.states.erase(node.data)
	elif node.has_method("graph_arrow_type"):
		self.sm_resource.current.transitions.erase(node.data)
	graph_edit.remove_node(node)

func inspect_node_data(node):
	if not editor_plugin.node_data_inspector.is_connected("inspecting_data_changed", self, "_on_node_data_inspector_changed"):
		editor_plugin.node_data_inspector.connect("inspecting_data_changed", self, "_on_node_data_inspector_changed", [node])
	
	editor_plugin.node_data_inspector.inspect(node.name, node.data)

func inspect_arrow_data(node):
	if not editor_plugin.arrow_data_inspector.is_connected("inspecting_data_changed", self, "_on_arrow_data_inspector_changed"):
		editor_plugin.arrow_data_inspector.connect("inspecting_data_changed", self, "_on_arrow_data_inspector_changed", [node])
	var states = []
	for s in self.sm_resource.current.states:
		states.append(s.name)
	editor_plugin.arrow_data_inspector.inspect(node.data, states)

func uninspect_node_data():
	editor_plugin.node_data_inspector.uninspect()
	if editor_plugin.node_data_inspector.is_connected("inspecting_data_changed", self, "_on_node_data_inspector_changed"):
			editor_plugin.node_data_inspector.disconnect("inspecting_data_changed", self, "_on_node_data_inspector_changed")

func uninspect_arrow_data():
	editor_plugin.arrow_data_inspector.uninspect()
	if editor_plugin.arrow_data_inspector.is_connected("inspecting_data_changed", self, "_on_arrow_data_inspector_changed"):
			editor_plugin.arrow_data_inspector.disconnect("inspecting_data_changed", self, "_on_arrow_data_inspector_changed")

#----- Signals -----

func _on_GraphEdit_gui_input(event):
	handle_gui_input(event)

func _on_GraphEdit_node_gui_input(event, node):
	handle_gui_input(event)

func _on_CreateNodeMenu_id_pressed(id):
	if id == 0:
		var n = add_state_node(graph_edit.nodes.get_local_mouse_position() + graph_edit.scroll_offset)
		if arrow_placing_start_node:
			connect_nodes(arrow_placing_start_node, n)
			arrow_placing_start_node = null
	if id == 1:#delete
		for n in graph_edit.selection:
			remove_node(n)
	if id == 2:#add transition
		assert(graph_edit.selection.size() > 0)
		graph_edit.place_arrow(graph_edit.selection[0])
		


func _on_GraphEdit_connect_node_request(start_node, end_node):
	if not graph_edit.check_is_node_connected(start_node, end_node):
		connect_nodes(start_node, end_node)
	else:
		printerr("%s aleady connected with %s!" % [start_node.name, end_node.name])


func _on_CreateSMRButton_pressed():
	if not state_machine.state_machine_resource:
		ur_lib.ur_create_state_machine_resource()
	select_state_machine_node(state_machine)


func _on_GraphEdit_editor_data_changed(e):
	self.sm_resource.zoom = e.zoom
	self.sm_resource.scroll_offset = e.scroll_offset


func _on_GraphEdit_about_to_remove_node(n):
	for arrow in graph_edit.arrows.get_children():
		if arrow.start_node == n or arrow.end_node == n:
			self.sm_resource.current.transitions.erase(arrow.data)
	uninspect_arrow_data()
	uninspect_node_data()

func _on_GraphEdit_select_node(node):
	if graph_edit.selection.size() == 1 and node.has_method("graph_node_type"):
		inspect_node_data(node)
	else:
		uninspect_node_data()
	if graph_edit.selection.size() == 1 and node.has_method("graph_arrow_type"):
		inspect_arrow_data(node)
	else:
		uninspect_arrow_data()
		

func _on_GraphEdit_unselect_node(node):
	uninspect_arrow_data()
	uninspect_node_data()

func _on_path_button_pressed(button:Button):
	uninspect_arrow_data()
	uninspect_node_data()
	
	self.sm_resource.go_to(button.get_meta("path"))
	
	generate_nodes_and_connections_with_resource()
	generate_path_buttons_from_path(self.sm_resource.path)

# go to the sub state machine
func _on_GraphEdit_node_reight_button_pressed(node):
	uninspect_arrow_data()
	uninspect_node_data()
	
	self.sm_resource.go_to(node.name)
	
	generate_nodes_and_connections_with_resource()
	generate_path_buttons_from_path(self.sm_resource.path)

# open state script
func _on_GraphEdit_node_double_pressed(node):
	if node.data.script:
		editor_plugin.get_editor_interface().edit_resource(load(node.data.script))
		pass


func _on_node_data_inspector_changed(key, value, node):
	if node:
		ur_lib.ur_just_dirty_the_editor()
		if key == 'name' and value is String and not value.empty():
			var old_name = node.name
			node.name = value
			value = node.name
			
			node.text = value
			node.data.name = value
			editor_plugin.node_data_inspector.title = value
			
			# change all the name in transition
			for t in self.sm_resource.current.transitions:
				if t.to == old_name:
					t.to = value
				if t.from == old_name:
					t.from = value
		elif key == 'script':
			node.data.script = value
		elif key == 'sub_state_machine':
			if value:
				node.data.sub_state_machine = self.sm_resource.gen_state_machine_data()
				node.right_button_tex = icon_tex
				
				# set back to the inspector
				editor_plugin.node_data_inspector.set_max_state_stack_size_spin_box_value(node.data.sub_state_machine.max_state_stack_size)
			else:
				node.data.sub_state_machine = null
				node.right_button_tex = null
		elif key == 'init':
			if value:
				node.data.init = true
				node.tip_text = 'Init'
				for n in graph_edit.nodes.get_children():
					if n != node:
						n.data.init = false
						n.tip_text = ''
						
			else:
				node.data.init = false
				node.tip_text = ''
		elif key == 'max_state_stack_size':
			node.data.sub_state_machine.max_state_stack_size = value

func _on_arrow_data_inspector_changed(key, value, arrow):
	if arrow:
		ur_lib.ur_just_dirty_the_editor()
		if key == 'from':
			var a = graph_edit.get_arrow(value, arrow.data.to)
			if a: # conflict
				printerr("%s and %s have already connected!" % [value, arrow.data.to])
			else:
				arrow.data.from = value
				arrow.update_from_data(graph_edit)
				# force update
				yield(get_tree(), "idle_frame")
				arrow.update()
				yield(get_tree(), "idle_frame")
				graph_edit._update_rows_position()
		elif key == 'to':
			var a = graph_edit.get_arrow(arrow.data.from, value)
			if a: # conflict
				printerr("%s and %s have already connected!" % [arrow.data.from, value])
			else:
				arrow.data.to = value
				arrow.update_from_data(graph_edit)
				# force update
				yield(get_tree(), "idle_frame")
				arrow.update()
				yield(get_tree(), "idle_frame")
				graph_edit._update_rows_position()
		elif key == 'cond':
			arrow.data.cond = value.duplicate()
			arrow.update_from_data(graph_edit)
			# force update
			yield(get_tree(), "idle_frame")
			arrow.update()
			yield(get_tree(), "idle_frame")
			graph_edit._update_rows_position()

