extends Node2D

var size


func _ready(): #TODO: move sfx to am
	$AudioStreamPlayer2D.play()
	# $AnimationPlayer.play(size)
	
	#$Explosion.amount = 8;
	#$Explosion.initial_velocity_max *= 2
	#$Explosion.initial_velocity_min *= 2
	
	# spwn circle effect
	var n = int(24)
	var vel = 200
	$base.emitting = false
	for i in n:
		var meow = $base.duplicate()
		add_child(meow)
		
		var ang = 2 * PI / n * i
		
		meow.direction = Vector2(cos(ang), sin(ang))
		meow.initial_velocity_min = vel
		meow.initial_velocity_max = vel
		meow.one_shot = true
		meow.emitting = true
		

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
