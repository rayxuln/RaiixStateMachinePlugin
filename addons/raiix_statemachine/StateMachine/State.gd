extends Node

class_name State

var state_machine:Node setget ,_on_get_state_machine
func _on_get_state_machine():
	return get_parent()

var agent:Node setget ,_on_get_agent
func _on_get_agent():
	return self.state_machine.agent

func _ready():
	# always assume that the first child is a state machine
	if get_child_count() > 0:
		var sm = get_child(0)
		sm.enable = false
		sm.auto_start = false

#----- Internal Methods ------
func _enter():
	if get_child_count() > 0:
		var sm = get_child(0)
		sm.agent_path = self.agent.get_path_to(sm)
		sm.start()

func _tick(agent, state_machine, delta):
	tick(agent, state_machine, delta)

func _exit():
	if get_child_count() > 0:
		get_child(0).stop()

#----- Public Methods-----

# override
func tick(agent, state_machine, delta):
	pass
