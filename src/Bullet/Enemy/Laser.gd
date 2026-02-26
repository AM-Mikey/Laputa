extends Bullet


func setup():
	speed = 64
	f_range = 64
	is_enemy_bullet = true
	rotation_degrees = get_rot(direction)


func _on_physics_process(_delta):
	velocity = speed * direction
	move_and_slide()
	if origin.distance_to(global_position) > f_range:
		do_fizzle("range")
