extends PhysicsProp

const ICON = preload("res://assets/Prop/BucketIcon.png")

func setup():
	w.emit_signal("finished_spawn_entities_step")
