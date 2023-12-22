extends Bullet

var texture: CompressedTexture2D
var texture_index: int
var collision_shape: RectangleShape2D



func _ready():
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

### SIGNALS ###

func _on_CollisionDetector_body_exited(body):
	pass # Replace with function body.
