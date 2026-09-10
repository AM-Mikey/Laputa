extends CPUParticles2D

func _ready():
	one_shot = true
	emitting = true
	am.play("enemy_die", self)
	if f.pc():
		f.pc().get_node("PlayerCamera").shake(4.0, 0.3, 3.0)

func _on_finished():
	queue_free()
