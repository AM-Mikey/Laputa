extends CharacterBody2D

func _physics_process(_delta):
	if $Bubble.visible:
		velocity.x = randf_range(-10, 10)
		velocity.y = -50
		move_and_slide()

func _on_area_exited(_area):
		$Bubble.visible = false
		am.play("effect_pop", self)
		$BubblePop.visible = true
		$BubblePop.one_shot = true
		$BubblePop.emitting = true

func _on_bubble_pop_finished():
	queue_free()
