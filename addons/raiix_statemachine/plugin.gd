tool
extends EditorPlugin

var StateMachineResourceEditor = preload("./StateMachineEditor/StateMachineResourceEditor.tscn")

var state_machine_resource_editor:Control = null

var script_select_dialog:Control = null
var node_data_inspector:Control = null
var arrow_data_inspector:Control = null

func _enter_tree():
	get_editor_interface().get_selection().connect("selection_changed", self, "_on_selecton_changed")
	get_editor_interface().get_inspector().connect("property_edited", self, "_on_inspector_property_edited")
	
	script_select_dialog = preload("./ScriptSelectDialog/ScriptSelectDialog.tscn").instance()
	get_editor_interface().get_base_control().add_child(script_select_dialog)
	
	node_data_inspector = preload("./StateMachineResourceNodeDataInspector/NodeDataInspector.tscn").instance()
	node_data_inspector.editor_plugin = self
	node_data_inspector.notification(NOTIFICATION_READY)
	
	arrow_data_inspector = preload("./StateMachineResourceArrowDataInspector/ArrowDataInspector.tscn").instance()
	arrow_data_inspector.editor_plugin = self
	arrow_data_inspector.notification(NOTIFICATION_READY)
	
func _exit_tree():
	script_select_dialog.queue_free()
	
	node_data_inspector.uninspect()
	node_data_inspector.queue_free()
	
	arrow_data_inspector.uninspect()
	arrow_data_inspector.queue_free()
	
	remove_state_machine_resource_editor()
	

#----- Methods ------
func add_state_machine_resource_edtor():
	state_machine_resource_editor = StateMachineResourceEditor.instance()
	state_machine_resource_editor.editor_plugin = self
	add_control_to_bottom_panel(state_machine_resource_editor, "State Machine")
	make_bottom_panel_item_visible(state_machine_resource_editor)


func remove_state_machine_resource_editor():
	if state_machine_resource_editor:
		node_data_inspector.uninspect()
		arrow_data_inspector.uninspect()
		remove_control_from_bottom_panel(state_machine_resource_editor)
		state_machine_resource_editor.free()
		

func get_script_file(node:Control, call_back, hide_call_back):
	if not script_select_dialog.is_connected("script_selected", node, call_back):
		script_select_dialog.connect("script_selected", node, call_back, [], CONNECT_ONESHOT)
		script_select_dialog.connect("about_to_hide", node, hide_call_back, [], CONNECT_ONESHOT)
	script_select_dialog.popup()

	
#----- Singals ------
func _on_selecton_changed():
	var selection = get_editor_interface().get_selection().get_selected_nodes()
	if selection.size() == 1:
		var n = selection[0] as Node
		for p in n.get_property_list():
			if p.name == "state_machine_resource":
				add_state_machine_resource_edtor()
				state_machine_resource_editor.select_state_machine_node(n)
				return
	remove_state_machine_resource_editor()

func _on_inspector_property_edited(p):
	if state_machine_resource_editor:
		if(p == 'state_machine_resource'):
			var selection = get_editor_interface().get_selection().get_selected_nodes()
			if selection.size() == 1:
				var n = selection[0] as Node
				for p in n.get_property_list():
					if p.name == "state_machine_resource":
						state_machine_resource_editor.select_state_machine_node(n)
						return
