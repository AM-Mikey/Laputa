extends Bullet

#TODO: consider having a instancable scene for bullet collision detectors

func _ready():
	damage = 4
	speed = 128
	f_range = 64
	rotation_degrees = get_rot(direction)
	setup_vis_notifier()

func _physics_process(_delta):
	if disabled: return
	velocity = speed * direction
	move_and_slide()
	if origin.distance_to(global_position) > f_range:
		do_fizzle("range")
