extends State


# override
func _physics_tick(agent, state_machine, delta) -> void:
	agent.update_movement()
	agent.update_gravity()


