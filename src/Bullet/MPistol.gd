extends Bullet

var texture: CompressedTexture2D
var texture_index: int
var collision_shape: RectangleShape2D

var max_spread_distance = 7



func _ready():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var spread_distance = int(rng.randf_range(max_spread_distance * -1, max_spread_distance))
	
	rotation_degrees = get_rot(direction)
	setup_vis_notifier()


func _physics_process(_delta):
	if disabled: return
	
	velocity = speed * direction
	set_velocity(velocity)
	move_and_slide()
	velocity = velocity
	if origin.distance_to(global_position) > f_range:
		do_fizzle("range")
