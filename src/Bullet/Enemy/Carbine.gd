extends Bullet

#TODO: consider having a instancable scene for bullet collision detectors

func _ready() -> void:
	damage = 4
	speed = 128
	f_range = 64
	is_enemy_bullet = true
	rotation_degrees = get_rot(direction)
	super._ready()

func _physics_process(delta: float) -> void:
	if disabled: return
	velocity = speed * direction
	move_and_slide()
	if origin.distance_to(global_position) > f_range:
		do_fizzle("range")

	super._physics_process(delta)
