extends Node2D

var size


func _ready(): #TODO: move sfx to am
	$AudioStreamPlayer2D.play()
	$AnimationPlayer.play(size)
	if f.pc():
		var player_distance = f.pc().global_position.distance_to(global_position)
		var max_distance := 256
		var max_shake_pixels : float
		match size:
			"Small": max_shake_pixels = 16
			"Medium": max_shake_pixels = 24
			"Large": max_shake_pixels = 32
		var shake_pixels = remap(player_distance, 0, max_distance, max_shake_pixels, 0.0)
		shake_pixels = clampf(shake_pixels, 0.0, max_shake_pixels)
		f.pc().get_node("PlayerCamera").shake(shake_pixels, 0.6, 16.0)

	#yield($AnimationPlayer, "animation_finished")
	await $AudioStreamPlayer2D.finished
	queue_free()
