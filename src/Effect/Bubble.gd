extends CharacterBody2D

func _physics_process(_delta):
	if $Bubble.visible:
		velocity.x = randf_range(-10, 10)
		velocity.y = -50
		move_and_slide()

func _on_area_exited(_area):
		$Bubble.visible = false
		am.play("effect_pop", self)
		if f.pc():
			var player_distance = f.pc().global_position.distance_to(global_position)
			var max_distance = 64
			var max_shake = 0.025
			var shake = remap(player_distance, 0, max_distance, max_shake, 0.0)
			oup.vibrate_impulse_light(shake)
		$BubblePop.visible = true
		$BubblePop.one_shot = true
		$BubblePop.emitting = true

func _on_bubble_pop_finished():
	queue_free()
