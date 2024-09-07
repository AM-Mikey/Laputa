extends CPUParticles2D

func _ready():
	emitting = true
	one_shot = true

func _on_finished():
	queue_free()
