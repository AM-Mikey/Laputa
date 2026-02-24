extends Bullet


func _ready() -> void:
	speed = 64
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
