extends Boss

const ICON = preload("res://assets/Actor/Enemy/BillyIcon.png")

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

func setup():
	w.emit_signal("finished_spawn_entities_step")
