tool
extends EditorPlugin

var StateMachineResourceEditor = preload("./StateMachineEditor/StateMachineResourceEditor.tscn")

var state_machine_resource_editor:Control = null

func _enter_tree():
	get_editor_interface().get_selection().connect("selection_changed", self, "_on_selecton_changed")
	
func _exit_tree():
	remove_state_machine_resource_editor()

#----- Methods ------
func add_state_machine_resource_edtor():
	state_machine_resource_editor = StateMachineResourceEditor.instance()
	state_machine_resource_editor.editor_plugin = self
	add_control_to_bottom_panel(state_machine_resource_editor, "State Machine")
	make_bottom_panel_item_visible(state_machine_resource_editor)
func remove_state_machine_resource_editor():
	if state_machine_resource_editor:
		remove_control_from_bottom_panel(state_machine_resource_editor)
		state_machine_resource_editor.free()
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
