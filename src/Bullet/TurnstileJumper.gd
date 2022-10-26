extends Bullet

var texture: StreamTexture
var texture_index: int
var collision_shape: RectangleShape2D



func _ready():
	rotation_degrees = get_rot(direction)

func _physics_process(_delta):
	if disabled: return
	
	velocity = speed * direction
	velocity = move_and_slide(velocity)
	if origin.distance_to(global_position) > f_range:
		fizzle("range")
