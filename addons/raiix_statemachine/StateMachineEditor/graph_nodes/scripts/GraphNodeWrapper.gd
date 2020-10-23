extends Control


#func _ready():
#	call_deferred("unwrapped")

func unwrapped():
	var c = null
	if get_child_count() > 0:
		c = get_child(0)
		remove_child(c)
	call_deferred("queue_free")
	return c
