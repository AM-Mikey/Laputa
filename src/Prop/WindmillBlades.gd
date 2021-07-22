extends Node2D

export var degrees_per_frame = 0.5
var rotation_around_point = 0

func _physics_process(delta):
	rotation_degrees += degrees_per_frame

	$BladeNorth.rotation_degrees -= degrees_per_frame
	$BladeWest.rotation_degrees -= degrees_per_frame
	$BladeEast.rotation_degrees -= degrees_per_frame
	$BladeSouth.rotation_degrees -= degrees_per_frame

	#global_position += Vector2(cos(rotation_around_point), sin(rotation_around_point))# * distance_from_point
