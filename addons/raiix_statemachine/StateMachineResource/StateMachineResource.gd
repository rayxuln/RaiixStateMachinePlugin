tool
extends Resource


class_name StateMachineResource

var block_written:bool = false

export(float) var zoom = 1 setget _on_set_zoom
func _on_set_zoom(v):
	if not block_written:
		zoom = v
export(Vector2) var scroll_offset = Vector2.ZERO setget _on_set_scroll_offset
func _on_set_scroll_offset(v):
	if not block_written:
		scroll_offset = v

export(Dictionary) var data = gen_state_machine_data()

var current:Dictionary setget , _on_get_current
func _on_get_current():
	return data

#----- Methods -----
func gen_state_machine_data():
	return {
		"states": [],
		"transitions": [],
		"max_state_stack_size": 1
	}
func gen_state_data():
	return {
		"name": "state",
		"script": null,
		"sub_state_machine": null,
		"offset": Vector2.ZERO,
		"init": false
	}
func gen_transition_data():
	return {
		"from": "",
		"to": "",
		"cond": null
	}

func update_editor_data(e):
	zoom = e.zoom
	scroll_offset = e.scroll_offset
#----- Signals ------
func _on_state_machine_data_property_changed(sm):
	data.init_state = sm.init_state_path
	data.max_state_stack_size = sm.max_state_stack_size
	

