tool
extends Reference


var the_editor:Control = null
var the_ur:UndoRedo = null

func _init(e):
	the_editor = e
	if the_editor.editor_plugin == null:
		yield(the_editor, "ready")
	the_ur = e.editor_plugin.get_undo_redo()

#----- Undo Redo -----
func ur_create_state_machine_resource():
	the_ur.create_action("Create state machine resource")
	the_ur.add_do_method(self, "_ur_create_state_machine_resource_do")
	the_ur.add_undo_method(self, "_ur_create_state_machine_resource_undo")
#	the_ur.add_do_property(state_machine, "state_machine_resource", StateMachineResource.new())
#	the_ur.add_undo_property(state_machine, "state_machine_resource", null)
	the_ur.commit_action()
func _ur_create_state_machine_resource_do():
	the_editor.state_machine.state_machine_resource = StateMachineResource.new()
#	the_editor.state_machine.connect("state_machine_data_property_changed", the_editor.state_machine.state_machine_resource, "_on_state_machine_data_property_changed")
	the_editor.refresh_inspector()
func _ur_create_state_machine_resource_undo():
	the_editor.state_machine.state_machine_resource = null
	the_editor.refresh_inspector()
	the_editor.select_state_machine_node(the_editor.state_machine)


func ur_just_dirty_the_editor():
	the_ur.create_action("State Machine Resource Dirty")
	the_ur.commit_action()
