extends Node2D

@onready var particles = get_children()
var direction: Vector2

func _ready():
	await get_tree().create_timer(.001).timeout #delay so blood direction is set properly
	emit_particles()
	await get_tree().create_timer(1.0).timeout #hard cutoff
	queue_free()

func emit_particles():
	for p in particles:
		p.direction = direction
		p.restart()
