extends Bullet

func setup():
	speed = 120.0
	rotation_degrees = get_rot(direction)

func _on_physics_process(_delta: float):
	velocity = speed * direction
	move_and_slide()
	if get_slide_collision_count() > 0:
		queue_free()

func _on_CollisionDetector_area_entered(area: Area2D):
	if area.get_collision_layer_value(17):
		var target = area.get_parent()
		target.hit(damage, get_blood_dir(target), $EnemyCollisionDetector)
		queue_free()
	elif area.get_collision_layer_value(4) or area.get_collision_layer_value(6):
		queue_free()

func _on_CollisionDetector_body_entered(_body: Node2D):
	queue_free()
