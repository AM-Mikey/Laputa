extends Bullet

#TODO: consider having a instancable scene for bullet collision detectors

func _ready():
	damage = 4
	speed = 128
	f_range = 64
	is_enemy_bullet = true
	rotation_degrees = get_rot(direction)

func _physics_process(_delta):
	if disabled: return
	
	velocity = speed * direction
	velocity = move_and_slide(velocity)
	if origin.distance_to(global_position) > f_range:
		fizzle("range")