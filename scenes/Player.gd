extends KinematicBody2D


func _ready():
	
	var i = $Tree.create_item(null)
	i.set_text(0, "6666")
	$Tree.create_item(null)
	i = $Tree.create_item(null)
	i.set_text(0, "7777")
	
	yield(get_tree().create_timer(5), "timeout")
	get_parent().add_child($Sprite.duplicate())
#	yield(get_tree().create_timer(20), "timeout")
#	queue_free()

	

#---- Methods -----
func is_change_action_pressed():
	return Input.is_action_just_pressed("change")
func is_back_action_preesed():
	return Input.is_action_just_pressed("back")
