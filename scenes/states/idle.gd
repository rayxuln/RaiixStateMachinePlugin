extends State

# override
func physics_tick(agent, state_machine, delta) -> void:
	agent.velocity.x = 0
	agent.update_gravity()


