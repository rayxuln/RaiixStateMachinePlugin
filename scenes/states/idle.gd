extends State

var last_time_stamp = 0

# override
func tick(agent, state_machine, delta) -> void:
	if OS.get_ticks_msec() - last_time_stamp > 1000:
		last_time_stamp = OS.get_ticks_msec()
		print("ticking_idle")


