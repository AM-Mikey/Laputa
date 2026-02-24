extends Bullet

var texture: CompressedTexture2D
var texture_index: int
var collision_shape: RectangleShape2D

var max_spread_distance = 7



func _ready() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	#var spread_distance = int(rng.randf_range(max_spread_distance * -1, max_spread_distance)) #unused

	rotation_degrees = get_rot(direction)
	super._ready()


func _physics_process(delta: float) -> void:
	if disabled: return
	velocity = speed * direction
	move_and_slide()
	if origin.distance_to(global_position) > f_range:
		do_fizzle("range")

	super._physics_process(delta)
