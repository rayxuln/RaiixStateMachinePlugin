extends State

var stagging = false

func enter(agent, state_machine):
	stagging = true
	agent.velocity.y = 0
	agent.anim_player.play("stagger")
	yield(get_tree().create_timer(0.2), "timeout")
	stagging = false

