extends Bullet

var start_velocity
@onready var ap = $AnimationPlayer



func setup():
	is_enemy_bullet = true
	ap.play("Rotate")
	gravity *= .5
	velocity = calc_velocity(speed)
	start_velocity = abs(velocity.x) + abs(velocity.y) / 2.0 #used to calculate animation slowdown


func _on_physics_process(delta):
	velocity.y += gravity * delta
	move_and_slide()

	var current_velocity = abs(velocity.x) + abs(velocity.y) /2 #used to calculate animation slowdown
	ap.speed_scale = current_velocity / start_velocity
	if ap.speed_scale < .1:
		ap.stop()


func calc_velocity(projectile_speed) -> Vector2:
	var out = velocity
	out.x = projectile_speed * direction.x
	out.y += gravity * get_physics_process_delta_time()

	if direction.y < 0:
		out.y = projectile_speed * direction.y
	return out
