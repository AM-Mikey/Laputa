extends Node2D

export var degrees_per_frame = 1


func _physics_process(delta):
	rotation_degrees += degrees_per_frame
