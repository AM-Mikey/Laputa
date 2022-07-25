extends Bullet

var texture: StreamTexture
var texture_index: int
var collision_shape: RectangleShape2D


var max_spread_distance = 7


func _ready():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var spread_distance = int(rng.randf_range(max_spread_distance * -1, max_spread_distance))
	
	match direction:
		Vector2.LEFT: rotation_degrees = 0
		Vector2.RIGHT: rotation_degrees = 180
		Vector2.UP: rotation_degrees = 90
		Vector2.DOWN: rotation_degrees = -90


func _physics_process(_delta):
	velocity = speed * direction
	
	if disabled == false:
		var _after_slide_velo = move_and_slide(velocity)
		var distance_from_origin = origin.distance_to(global_position);
		if distance_from_origin > f_range:
			fizzle("range")
