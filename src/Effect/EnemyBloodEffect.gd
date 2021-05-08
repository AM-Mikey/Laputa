extends Node2D

onready var particles = get_children()
var direction: Vector2

func _ready():
	yield(get_tree().create_timer(.001), "timeout") #delay so blood direction is set properly
	#print("emitting blood particles")
	#print(particles)
	emit_particles()
	yield(get_tree().create_timer(1.0), "timeout") #hard cutoff
	queue_free()

func _input(event):
	if event.is_action_pressed("debug"):
		emit_particles()

func emit_particles():
	for p in particles:
		p.direction = direction
		#print(p.direction)
		p.restart()
