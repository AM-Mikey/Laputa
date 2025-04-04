extends TileAnimator


func setup():
	frame_counts = {
	"waterfall": 10,
	"grass": 2,}
	create_simple_timer("waterfall", 0.1)
	create_simple_timer("grass", 1.0)

func editor_enter():
	for timer in timers:
		timers[timer].stop()
	reset_animation()

func editor_exit():
	for timer in timers:
		timers[timer].start()
	setup_animation_groups()
