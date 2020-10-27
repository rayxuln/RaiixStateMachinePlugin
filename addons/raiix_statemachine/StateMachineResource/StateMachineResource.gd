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

var path:String = "/"

var current:Dictionary setget , _on_get_current
func _on_get_current():
	return get_state_machine_data_from_path(path)



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
		"cond": []
	}

func update_editor_data(e):
	zoom = e.zoom
	scroll_offset = e.scroll_offset

func go_to(p:String):
	if p.empty():
		return
	if p[0] != '/':
		if path[path.length()-1] == '/':
			path += p
		else:
			path += '/' + p
	else:
		path = p

func get_state(sm_data, s_name):
	for s in sm_data.states:
		if s.name == s_name:
			return s
	return null

func get_state_machine_data_from_path(p:String):
	if p.empty():
		return data
	var ss = p.split('/')
	var temp = data
	for s in ss:
		if not s.empty():
			var state = get_state(temp, s)
			if state:
				if state.sub_state_machine:
					temp = state.sub_state_machine
				else:
					printerr("[SMR]Bad path: %s, state %s doesn't have a state machine" % [p, s])
					return data
			else:
				printerr("[SMR]Bad path: %s, can't find state %s" % [p, s])
				return data
	return temp

func _generate_state_machine_from_state_machine_date(sm_data):
	var state_machine = StateMachine.new()
	state_machine.name = "StateMachine"
	state_machine.auto_start = false
	state_machine.enable = false
	state_machine.max_state_stack_size = sm_data.max_state_stack_size
	return state_machine

func _generate_states_from_state_machine_data(state_machine:StateMachine, sm_data):
	# add states
	for state in sm_data.states:
		if state.name == 'back':
			continue
		var state_node = State.new()
		state_node.name = state.name
		if state.script != null:
			state_node.set_script(load(state.script))
		state_machine.add_child(state_node)
		
		if state.init:
			state_machine.init_state_path = state.name
		
		if state.sub_state_machine != null:
			var sub_state_machine_node = _generate_state_machine_from_state_machine_date(sm_data)
			state_node.add_child(sub_state_machine_node)
			sub_state_machine_node.sub_state_machine = true
			
			_generate_states_from_state_machine_data(sub_state_machine_node, state.sub_state_machine)
	
	# add transitions
	for t in sm_data.transitions:
		var conds = t.cond
		if conds.size() > 0:
			for c in conds:
				state_machine.add_transition(t.from, t.to, c)
		else:
			state_machine.add_transition(t.from, t.to)

func generate_states(state_machine:StateMachine):
	_generate_states_from_state_machine_data(state_machine, data)

#----- Signals ------
#func _on_state_machine_data_property_changed(sm):
#	data.init_state = sm.init_state_path
#	data.max_state_stack_size = sm.max_state_stack_size
	

