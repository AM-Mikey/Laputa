extends Boss

const ICON = preload("res://assets/Icon/BossIcon.png")

@onready var ap = $AnimationPlayer

var fly_speed: = Vector2(60.0, 60.0)

func setup():
	w.emit_signal("finished_spawn_entities_step")
