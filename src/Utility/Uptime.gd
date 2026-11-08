extends Node

var total_uptime: int = 0 #milliseconds #outdated until you call get_total_uptime()
var session_start_tick: int = 0 #milliseconds

func start_tracking_uptime(loaded_time: int = 0):
	total_uptime = loaded_time
	session_start_tick = Time.get_ticks_msec()

func get_total_uptime() -> int:
	var session_elapsed = Time.get_ticks_msec()
	return total_uptime + session_elapsed
