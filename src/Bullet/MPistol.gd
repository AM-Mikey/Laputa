extends Bullet

var texture: CompressedTexture2D
var texture_index: int
var collision_shape: RectangleShape2D

var max_spread_distance = 7



func setup():
	rng.randomize()
	#var spread_distance = int(rng.randf_range(max_spread_distance * -1, max_spread_distance)) #unused
	rotation_degrees = get_rot(direction)


func _on_physics_process(_delta):
	velocity = speed * direction
	move_and_slide()
	if origin.distance_to(global_position) > f_range:
		do_fizzle("range")
