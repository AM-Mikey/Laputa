extends Bullet

var texture: CompressedTexture2D
var texture_index: int
var collision_shape: RectangleShape2D



func setup():
	rotation_degrees = get_rot(direction)

func _on_physics_process(_delta):
	velocity = speed * direction
	move_and_slide()
	if origin.distance_to(global_position) > f_range:
		do_fizzle("range")



### SIGNALS ###

func _on_CollisionDetector_body_exited(_body):
	pass # Replace with function body.
