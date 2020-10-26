tool
extends EditorPlugin

var StateMachineResourceEditor = preload("./StateMachineEditor/StateMachineResourceEditor.tscn")

var state_machine_resource_editor:Control = null

var script_select_dialog:Control = null
var node_data_inspector:Control = null
var arrow_data_inspector:Control = null

var remote_debug_server:Node = null
var remote_viewer:Popup = null

func _enter_tree():
	get_editor_interface().get_selection().connect("selection_changed", self, "_on_selecton_changed")
	get_editor_interface().get_inspector().connect("property_edited", self, "_on_inspector_property_edited")
	
	script_select_dialog = preload("./ScriptSelectDialog/ScriptSelectDialog.tscn").instance()
	get_editor_interface().get_base_control().add_child(script_select_dialog)
	
	node_data_inspector = preload("./StateMachineResourceNodeDataInspector/NodeDataInspector.tscn").instance()
	node_data_inspector.editor_plugin = self
	node_data_inspector.name = "State"
	node_data_inspector.notification(NOTIFICATION_READY)
	
	arrow_data_inspector = preload("./StateMachineResourceArrowDataInspector/ArrowDataInspector.tscn").instance()
	arrow_data_inspector.editor_plugin = self
	arrow_data_inspector.name = "Transition"
	arrow_data_inspector.notification(NOTIFICATION_READY)
	
	var temp = preload("./RemoteDebug/RemoteDebugClient.gd") as Script
	add_autoload_singleton("RemoteDebugClient", temp.resource_path)
	
	add_tool_menu_item("State Machine Remote Viewer", self, "_on_open_remote_viewer")
	

func _ready():
	remote_debug_server = preload("./RemoteDebug/RemoteDebugServer.gd").new()
	add_child(remote_debug_server)
	

func _exit_tree():
	script_select_dialog.queue_free()
	
	node_data_inspector.uninspect()
	node_data_inspector.queue_free()
	
	arrow_data_inspector.uninspect()
	arrow_data_inspector.queue_free()
	
	remove_state_machine_resource_editor()
	
	remove_tool_menu_item("State Machine Remote Viewer")
	if remote_viewer:
		remote_viewer.queue_free()
		remote_viewer = null
	
	remove_autoload_singleton("RemoteDebugClient")
	

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

func _on_open_remote_viewer(ud):
	if not remote_viewer:
		remote_viewer = preload("./StateMachineRemoteViewer/RemoteViewer.tscn").instance()
		get_editor_interface().get_base_control().add_child(remote_viewer)
		remote_viewer.connect("popup_hide", self, "_on_remote_viewer_hide")
	remote_viewer.popup_centered()

func _on_remote_viewer_hide():
	pass

