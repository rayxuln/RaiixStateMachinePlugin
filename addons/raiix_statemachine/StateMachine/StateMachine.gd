extends Node

class_name StateMachine

export(NodePath) var agent_path:NodePath setget _on_set_agent_path, _on_get_agent_path
func _on_set_agent_path(v):
	agent_path = v
	agent = get_node_or_null(agent_path)
func _on_get_agent_path():
	return agent_path
var agent:Node = null

# The state stack is a ring buf
# so no copying cost
var state_stack:Array = []
export(int) var max_state_stack_size:int = 1
var state_stack_head = 0
var state_stack_tail = 0

# A transition
var transitions:Dictionary = {}


export(NodePath) var init_state_path:NodePath setget _on_set_init_state_path, _on_get_init_state_path
func _on_set_init_state_path(v):
	init_state_path = v
	init_state = get_node_or_null(init_state_path)
func _on_get_init_state_path():
	return init_state_path
var init_state:Node = null

var current_state:State

export(bool) var enable:bool = false
export(bool) var auto_start:bool = true

export(Resource) var state_machine_resource:Resource = null

func _ready():
	if auto_start:
		start()

	
func _process(delta):
	if not enable:
		return
	if current_state:
		current_state._tick(agent, self, delta)
		
		# find the new state that meet the conditions of current_state's transitions
		if transitions.has(current_state.name):
			var ts = transitions[current_state.name]
			if ts is Array:
				for t in ts:
					if t.cond:
						if SMTCS.eval(t.cond, agent):
							if change_state(t.to_state):
								break
					else:
						if change_state(t.to_state):
							break

#------ Methods -----
func start():
	agent = get_node_or_null(agent_path)
	init_state = get_node_or_null(init_state_path)
	
	enable = true
	state_stack.resize(max_state_stack_size)
	state_stack_head = 0
	state_stack_tail = 0
	
	change_state(init_state)

func stop():
	current_state = null
	enable = false
	state_stack_head = 0
	state_stack_tail = 0

func pause():
	enable = false

func resume():
	enable = true

func _transition(from_state, to_state, cond=null):
	return {
		"from_state": from_state,
		"to_state": to_state,
		"cond": cond
	}

func add_transition(from_state:String, to_state:String, cond=null):
	if cond and (not (cond is String) and not (cond is Dictionary)):
		printerr("Unsupported type of condition!")
		return
	if not transitions.has(from_state):
		transitions[from_state] = []
	transitions[from_state].append(_transition(from_state, to_state, cond))

func remove_transition(from_state:String, index:int):
	var ts = transitions[from_state]
	if ts is Array:
		ts.remove(index)

func state_stack_push(state):
	state_stack[state_stack_tail] = state
	var new_tail = (state_stack_tail + 1) % max_state_stack_size
	if state_stack[new_tail] != null and state_stack_tail == state_stack_head:
		state_stack_head = (state_stack_head + 1) % max_state_stack_size
	state_stack_tail = new_tail
	

func state_stack_pop():
	if state_stack_empty():
		return null
	state_stack_tail = (max_state_stack_size + state_stack_tail - 1) % max_state_stack_size
	var state  = state_stack[state_stack_tail]
	state_stack[state_stack_tail] = null
	return state

func state_stack_empty():
	return state_stack_head == state_stack_tail and state_stack[state_stack_head] == null

func change_state(new_state):
	if new_state is String:
		if new_state == 'back':
			if state_stack_empty():
				printerr("The state stack(%s) is empty!" % name)
				return false
			if current_state:
				current_state._exit()
			current_state = state_stack_pop()
			if current_state:
				current_state._enter()
			return
		var s = get_node_or_null(new_state)
		if s == null:
			printerr("Change state fail, the %s state of %s is null." % [new_state, name])
			return false
		new_state = s
	if current_state:
		current_state._exit()
		state_stack_push(current_state)
	current_state = new_state
	if current_state:
		current_state._enter()
	return true

func get_current_state_name():
	if current_state:
		return current_state.name
	return "Null State"
