extends Bullet


func _ready():
	speed = 64
	f_range = 64
	is_enemy_bullet = true
	rotation_degrees = get_rot(direction)
	setup_vis_notifier()


func _physics_process(_delta):
	if disabled: return
	velocity = speed * direction
	move_and_slide()
	if origin.distance_to(global_position) > f_range:
		do_fizzle("range")
