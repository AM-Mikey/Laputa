extends Node2D

func _process(_delta):
	$Panel.material.set_shader_parameter("camera_zoom", get_viewport().get_camera_2d().zoom)
