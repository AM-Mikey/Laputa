extends Bullet

var texture: CompressedTexture2D
var texture_index: int
var collision_shape: RectangleShape2D



func _ready() -> void:
	rotation_degrees = get_rot(direction)
	super._ready()

func _physics_process(delta: float) -> void:
	if disabled: return
	velocity = speed * direction
	move_and_slide()
	if origin.distance_to(global_position) > f_range:
		do_fizzle("range")

	super._physics_process(delta)
