extends KinematicBody2D


var velocity = Vector2.ZERO
var gravity = Vector2.DOWN * 9.8

export(float) var move_speed = 200
export(float) var jump_speed = 200

onready var anim_player = $AnimationPlayer

#----- Methods -----
func is_move_input():
	return Input.is_action_pressed("move_left") || Input.is_action_pressed("move_right")
func update_movement():
	var input_x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	
	velocity.x = input_x * move_speed
	
	move_and_slide(velocity)
func update_gravity():
	velocity += gravity
	
	velocity = move_and_slide(velocity)
	if global_position.y > 300:
		velocity.y = 0
		global_position.y = 300
	
func jump():
	velocity.y += jump_speed
	
	


func _on_MovmentStateMachine_state_changed(old_state, new_state, by_tansition):
	$Label.text = new_state
