extends Node2D

@onready var particles = get_children()
@export var direction: Vector2

func _ready():
	for p in get_children():
		p.emitting = false
	await get_tree().create_timer(.001).timeout #delay so blood direction is set properly
	print(direction)
	for p in get_children():
		p.direction = direction
		p.one_shot = true
		p.restart()
		
	await get_tree().create_timer(1.0).timeout #hard cutoff
	queue_free()
