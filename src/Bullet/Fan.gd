extends Bullet

var texture: CompressedTexture2D
var texture_index: int
var collision_shape: RectangleShape2D


func setup():
	rotation_degrees = get_rot(direction)

func _physics_process(_delta):
	velocity = speed * direction
	move_and_slide()
	if origin.distance_to(global_position) > f_range:
		do_fizzle("range")
