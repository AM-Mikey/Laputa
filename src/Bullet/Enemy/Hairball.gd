extends Bullet

var start_velocity
@onready var ap = $AnimationPlayer



func _ready():
	is_enemy_bullet = true
	add_to_group("WindBullets")
	ap.play("Rotate")
	gravity *= .5
	
	velocity = calc_velocity(speed, direction)
	start_velocity = abs(velocity.x) + abs(velocity.y) / 2.0 #used to calculate animation slowdown
	setup_vis_notifier()


func _physics_process(delta):
	if disabled: return
	
	velocity.y += gravity * delta
	set_velocity(velocity)
	move_and_slide()
	velocity = velocity
	
	var current_velocity = abs(velocity.x) + abs(velocity.y) /2 #used to calculate animation slowdown
	ap.speed_scale = current_velocity / start_velocity
	if ap.speed_scale < .1:
		ap.stop()


func calc_velocity(projectile_speed, direction) -> Vector2:
	var out = velocity
	out.x = projectile_speed * direction.x
	out.y += gravity * get_physics_process_delta_time()
	
	if direction.y < 0:
		out.y = projectile_speed * direction.y
	return out

func on_break(method):
	if disabled == false:
		do_fizzle("bullet")
