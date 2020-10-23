extends KinematicBody2D



func _ready():
	$MovmentStateMachine.add_transition("idle", "run", "is_change_action_pressed()")
	$MovmentStateMachine.add_transition("run", "idle", "is_change_action_pressed()")
	$MovmentStateMachine.add_transition("run", "back", "is_back_action_preesed()")
	$MovmentStateMachine.add_transition("idle", "back", "is_back_action_preesed()")

#---- Methods -----
func is_change_action_pressed():
	return Input.is_action_just_pressed("change")
func is_back_action_preesed():
	return Input.is_action_just_pressed("back")
