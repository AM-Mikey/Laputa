extends TileAnimator


func setup():
	frame_counts = {
	"flame": 4,
	"light": 2,}
	create_simple_timer("flame", 0.2)
	create_simple_timer("light", 7.0)

func editor_enter():
	for timer in timers:
		timers[timer].stop()
	reset_animation()

func editor_exit():
	for timer in timers:
		timers[timer].start()
	setup_animation_groups()
