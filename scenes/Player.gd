extends KinematicBody2D


#---- Methods -----
func is_change_action_pressed():
	return Input.is_action_just_pressed("change")
func is_back_action_preesed():
	return Input.is_action_just_pressed("back")
